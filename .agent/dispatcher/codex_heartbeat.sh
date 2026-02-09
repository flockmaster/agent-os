#!/usr/bin/env bash
# ============================================================
# Codex Heartbeat Monitor v2.1 — Bash Edition (T-HB-06)
#
# Unix/macOS 版心跳模块，功能与 CodexHeartbeat.psm1 对齐。
# 使用后台进程 (&) + PID 文件实现异步任务监控。
#
# 用法:
#   source .agent/dispatcher/codex_heartbeat.sh
#   codex_start_task "T-001" "实现用户登录" "/path/to/project"
#   codex_wait_task "T-001" 10 3600 120
#   codex_list_tasks
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TASK_DIR="$AGENT_ROOT/memory/heartbeat_tasks"
LOG_DIR="$AGENT_ROOT/memory/heartbeat_logs"

# 初始化
codex_init_heartbeat() {
    mkdir -p "$TASK_DIR" "$LOG_DIR"
    echo "[OK] Heartbeat system initialized (bash)"
    echo "     Task dir: $TASK_DIR"
    echo "     Log dir:  $LOG_DIR"
}

# 启动任务
codex_start_task() {
    local task_id="$1"
    local prompt="$2"
    local work_dir="${3:-$(pwd)}"
    local model="${4:-}"
    local timeout="${5:-3600}"
    local sandbox="${6:-danger-full-access}"

    codex_init_heartbeat

    local lastmsg_file="$LOG_DIR/${task_id}-lastmsg.txt"
    local state_file="$TASK_DIR/${task_id}.json"
    local pid_file="$TASK_DIR/${task_id}.pid"
    local stdout_log="$LOG_DIR/${task_id}-stdout.log"

    # 构造 codex 命令
    local cmd_args="exec --full-auto -o $lastmsg_file -C $work_dir"
    [ -n "$model" ] && cmd_args="$cmd_args -m $model"
    [ "$sandbox" = "danger-full-access" ] && cmd_args="$cmd_args --sandbox danger-full-access"
    cmd_args="$cmd_args $prompt"

    echo ""
    echo "[LAUNCH] Async task: $task_id"
    echo "         Args: codex $cmd_args"

    # 后台启动
    codex $cmd_args > "$stdout_log" 2>&1 &
    local pid=$!
    echo "$pid" > "$pid_file"

    # 写入状态文件
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$state_file" <<EOF
{
  "taskId": "$task_id",
  "prompt": "$prompt",
  "status": "RUNNING",
  "pid": $pid,
  "startTime": "$now",
  "lastHeartbeat": "$now",
  "progress": "Process started (PID: $pid)",
  "lastMsgFile": "$lastmsg_file",
  "stdoutLog": "$stdout_log",
  "lastMsgSize": 0,
  "timeout": $timeout,
  "sandboxMode": "$sandbox",
  "exitCode": null,
  "error": null
}
EOF

    echo "         PID: $pid"
    echo "         State: $state_file"
    echo ""
}

# 检查任务状态
codex_get_status() {
    local task_id="$1"
    local state_file="$TASK_DIR/${task_id}.json"

    if [ ! -f "$state_file" ]; then
        echo "UNKNOWN"
        return 1
    fi

    local status pid
    status=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('status','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    pid=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('pid',0))" 2>/dev/null || echo "0")

    if [ "$status" = "RUNNING" ] && [ "$pid" != "0" ]; then
        if ! kill -0 "$pid" 2>/dev/null; then
            # 进程已结束
            wait "$pid" 2>/dev/null
            local exit_code=$?
            local now
            now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

            if [ "$exit_code" -eq 0 ]; then
                _update_state "$state_file" "DONE" "$now" "Process completed (exit 0)" "$exit_code"
                status="DONE"
            else
                _update_state "$state_file" "ERROR" "$now" "Process failed (exit $exit_code)" "$exit_code"
                status="ERROR"
            fi
        else
            # 进程运行中，检查输出文件增长
            local lastmsg_file stdout_log
            lastmsg_file=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('lastMsgFile',''))" 2>/dev/null)
            stdout_log=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('stdoutLog',''))" 2>/dev/null)

            local activity=false
            if [ -f "$stdout_log" ]; then
                local current_size
                current_size=$(wc -c < "$stdout_log" 2>/dev/null || echo "0")
                local last_size
                last_size=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('lastMsgSize',0))" 2>/dev/null || echo "0")

                if [ "$current_size" -gt "$last_size" ]; then
                    activity=true
                    local now
                    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    python3 -c "
import json
with open('$state_file','r') as f: d=json.load(f)
d['lastHeartbeat']='$now'
d['lastMsgSize']=$current_size
d['progress']='Running... (output: ${current_size} bytes)'
with open('$state_file','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
                fi
            fi
        fi
    fi

    echo "$status"
}

# 等待任务完成（含心跳超时）
codex_wait_task() {
    local task_id="$1"
    local poll_interval="${2:-10}"
    local timeout="${3:-3600}"
    local hb_timeout="${4:-120}"

    local start_time
    start_time=$(date +%s)
    local spin_chars=('|' '/' '-' '\')
    local spin_idx=0
    local poll_count=0

    echo ""
    echo "[WATCH] Monitoring task: $task_id"
    echo "        Poll: ${poll_interval}s | Timeout: ${timeout}s | HB Timeout: ${hb_timeout}s"
    echo "================================================================="

    while true; do
        local now
        now=$(date +%s)
        local elapsed=$((now - start_time))
        poll_count=$((poll_count + 1))

        if [ "$elapsed" -gt "$timeout" ]; then
            echo ""
            echo "[TIMEOUT] Task $task_id timed out (${timeout}s)"
            return 1
        fi

        local status
        status=$(codex_get_status "$task_id")
        local state_file="$TASK_DIR/${task_id}.json"

        # 心跳超时检查
        if [ "$status" = "RUNNING" ] && [ -f "$state_file" ]; then
            local last_hb
            last_hb=$(python3 -c "
import json, datetime
d=json.load(open('$state_file'))
hb=datetime.datetime.fromisoformat(d['lastHeartbeat'].replace('Z','+00:00'))
now=datetime.datetime.now(datetime.timezone.utc)
print(int((now-hb).total_seconds()))
" 2>/dev/null || echo "0")

            if [ "$last_hb" -gt "$hb_timeout" ]; then
                echo ""
                echo "[DEAD] Heartbeat timeout! No activity for ${hb_timeout}s"
                return 2
            fi
        fi

        local spin_char="${spin_chars[$((spin_idx % 4))]}"
        spin_idx=$((spin_idx + 1))
        local elapsed_fmt
        elapsed_fmt=$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))

        case "$status" in
            DONE)
                echo ""
                echo "[DONE] Task $task_id completed! Time: $elapsed_fmt"
                return 0
                ;;
            ERROR)
                echo ""
                echo "[FAIL] Task $task_id failed!"
                return 1
                ;;
            CANCELLED)
                echo ""
                echo "[CANCELLED] Task $task_id was cancelled"
                return 3
                ;;
            RUNNING)
                local progress
                progress=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('progress','...'))" 2>/dev/null || echo "...")
                echo "$spin_char [$elapsed_fmt] $task_id | $progress | #$poll_count"
                ;;
        esac

        sleep "$poll_interval"
    done
}

# 列出所有任务
codex_list_tasks() {
    codex_init_heartbeat
    local files
    files=$(ls "$TASK_DIR"/*.json 2>/dev/null)
    if [ -z "$files" ]; then
        echo "[EMPTY] No tasks"
        return
    fi

    printf "%-12s %-10s %-8s %-10s %s\n" "TASK_ID" "STATUS" "PID" "ELAPSED" "PROGRESS"
    printf "%-12s %-10s %-8s %-10s %s\n" "-------" "------" "---" "-------" "--------"

    for f in $files; do
        python3 -c "
import json, datetime
d=json.load(open('$f'))
elapsed=''
if d.get('startTime'):
    try:
        st=datetime.datetime.fromisoformat(d['startTime'].replace('Z','+00:00'))
        now=datetime.datetime.now(datetime.timezone.utc)
        s=int((now-st).total_seconds())
        elapsed=f'{s//3600:02d}:{(s%3600)//60:02d}:{s%60:02d}'
    except: pass
print(f\"{d.get('taskId','?'):<12s} {d.get('status','?'):<10s} {d.get('pid',0):<8} {elapsed:<10s} {d.get('progress','')[:40]}\")
" 2>/dev/null
    done
}

# 停止任务
codex_stop_task() {
    local task_id="$1"
    local state_file="$TASK_DIR/${task_id}.json"
    local pid_file="$TASK_DIR/${task_id}.pid"

    if [ ! -f "$state_file" ]; then
        echo "[WARN] Task $task_id not found"
        return 1
    fi

    local pid
    pid=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('pid',0))" 2>/dev/null || echo "0")

    if [ "$pid" != "0" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        echo "[STOP] Task $task_id stopped (PID: $pid)"
    fi

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    _update_state "$state_file" "CANCELLED" "$now" "Cancelled by user" ""
}

# 清理所有任务
codex_clear_tasks() {
    rm -f "$TASK_DIR"/*.json "$TASK_DIR"/*.pid "$LOG_DIR"/*
    echo "[CLEAN] All task records cleared"
}

# 内部: 更新状态文件
_update_state() {
    local state_file="$1" status="$2" timestamp="$3" progress="$4" exit_code="$5"
    python3 -c "
import json
with open('$state_file','r') as f: d=json.load(f)
d['status']='$status'
d['lastHeartbeat']='$timestamp'
d['progress']='$progress'
if '$exit_code': d['exitCode']=$exit_code
with open('$state_file','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
}

echo "💓 Codex Heartbeat (bash) loaded. Commands: codex_start_task, codex_wait_task, codex_list_tasks, codex_stop_task"
