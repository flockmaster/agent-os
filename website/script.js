// ===== 粒子动画 =====
function createParticles() {
    const particlesBg = document.getElementById('particles-bg');
    const particleCount = 50;
    
    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.style.position = 'absolute';
        particle.style.width = Math.random() * 3 + 'px';
        particle.style.height = particle.style.width;
        particle.style.background = 'white';
        particle.style.borderRadius = '50%';
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        particle.style.opacity = Math.random() * 0.5 + 0.2;
        particle.style.animation = `twinkle ${Math.random() * 3 + 2}s ease-in-out infinite`;
        particlesBg.appendChild(particle);
    }
}

// 闪烁动画
const style = document.createElement('style');
style.textContent = `
    @keyframes twinkle {
        0%, 100% { opacity: 0.2; }
        50% { opacity: 1; }
    }
`;
document.head.appendChild(style);

// ===== 导航栏滚动效果 =====
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(10, 14, 39, 0.95)';
        navbar.style.boxShadow = '0 5px 20px rgba(0, 0, 0, 0.3)';
    } else {
        navbar.style.background = 'rgba(10, 14, 39, 0.8)';
        navbar.style.boxShadow = 'none';
    }
});

// ===== 平滑滚动 =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// ===== Tab 切换 =====
const tabButtons = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

tabButtons.forEach(button => {
    button.addEventListener('click', () => {
        const targetTab = button.getAttribute('data-tab');
        
        // 移除所有活动状态
        tabButtons.forEach(btn => btn.classList.remove('active'));
        tabContents.forEach(content => content.classList.remove('active'));
        
        // 添加当前活动状态
        button.classList.add('active');
        document.querySelector(`.tab-content[data-tab="${targetTab}"]`).classList.add('active');
    });
});

// ===== 复制按钮 =====
document.querySelectorAll('.copy-btn').forEach(button => {
    button.addEventListener('click', async () => {
        const code = button.getAttribute('data-code').replace(/&#10;/g, '\n');
        
        try {
            await navigator.clipboard.writeText(code);
            
            // 显示复制成功提示
            const originalHTML = button.innerHTML;
            button.innerHTML = `
                <svg viewBox="0 0 24 24" width="16" height="16">
                    <path fill="currentColor" d="M9,20.42L2.79,14.21L5.62,11.38L9,14.77L18.88,4.88L21.71,7.71L9,20.42Z"/>
                </svg>
            `;
            button.style.background = '#10b981';
            
            setTimeout(() => {
                button.innerHTML = originalHTML;
                button.style.background = '';
            }, 2000);
        } catch (err) {
            console.error('复制失败:', err);
        }
    });
});

// ===== 终端动画 =====
function animateTerminal() {
    const activePanel = document.querySelector('.demo-panel.active');
    if (!activePanel) return;
    const terminalLines = activePanel.querySelectorAll('.terminal-line');
    terminalLines.forEach((line, index) => {
        line.style.opacity = '0';
        setTimeout(() => {
            line.style.animation = 'terminal-appear 0.3s ease-in-out forwards';
        }, index * 200);
    });
}

// ===== 演示 Tab 切换 (T-WEB-05) =====
const demoTabButtons = document.querySelectorAll('.demo-tab-btn');
const demoPanels = document.querySelectorAll('.demo-panel');

demoTabButtons.forEach(button => {
    button.addEventListener('click', () => {
        const targetDemo = button.getAttribute('data-demo');
        
        demoTabButtons.forEach(btn => btn.classList.remove('active'));
        demoPanels.forEach(panel => panel.classList.remove('active'));
        
        button.classList.add('active');
        const targetPanel = document.querySelector(`.demo-panel[data-demo="${targetDemo}"]`);
        if (targetPanel) {
            targetPanel.classList.add('active');
            animateTerminal();
        }
    });
});

// ===== Intersection Observer for animations =====
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            
            // 特殊处理终端动画
            if (entry.target.classList.contains('demo-section')) {
                animateTerminal();
            }
        }
    });
}, observerOptions);

// 观察所有需要动画的元素
document.querySelectorAll('.feature-card, .pain-card, .arch-layer, .demo-section, .role-card, .mode-card, .comparison-section').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
    observer.observe(el);
});

// ===== 计数动画 =====
function animateCounter(element, target, duration = 2000) {
    let current = 0;
    const increment = target / (duration / 16);
    
    const updateCounter = () => {
        current += increment;
        if (current < target) {
            element.textContent = Math.floor(current);
            requestAnimationFrame(updateCounter);
        } else {
            element.textContent = target;
        }
    };
    
    updateCounter();
}

// ===== 鼠标跟随光效 =====
document.addEventListener('mousemove', (e) => {
    const mouseX = e.clientX;
    const mouseY = e.clientY;
    
    // 创建光效元素
    const glow = document.createElement('div');
    glow.style.position = 'fixed';
    glow.style.left = mouseX + 'px';
    glow.style.top = mouseY + 'px';
    glow.style.width = '200px';
    glow.style.height = '200px';
    glow.style.background = 'radial-gradient(circle, rgba(255, 107, 53, 0.1), transparent)';
    glow.style.pointerEvents = 'none';
    glow.style.transform = 'translate(-50%, -50%)';
    glow.style.transition = 'opacity 0.3s ease-out';
    glow.style.opacity = '0';
    glow.style.zIndex = '9999';
    
    document.body.appendChild(glow);
    
    setTimeout(() => {
        glow.style.opacity = '1';
    }, 10);
    
    setTimeout(() => {
        glow.style.opacity = '0';
        setTimeout(() => glow.remove(), 300);
    }, 200);
});

// ===== Neural Network Animation =====
function createNeuralConnections() {
    const brainContainer = document.querySelector('.brain-container');
    if (!brainContainer) return;
    
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '400');
    svg.setAttribute('height', '400');
    svg.style.position = 'absolute';
    svg.style.top = '0';
    svg.style.left = '0';
    svg.style.pointerEvents = 'none';
    
    const nodes = document.querySelectorAll('.neural-node');
    const core = document.querySelector('.brain-core');
    
    if (core && nodes.length > 0) {
        const coreRect = core.getBoundingClientRect();
        const containerRect = brainContainer.getBoundingClientRect();
        const coreX = coreRect.left - containerRect.left + coreRect.width / 2;
        const coreY = coreRect.top - containerRect.top + coreRect.height / 2;
        
        nodes.forEach(node => {
            const nodeRect = node.getBoundingClientRect();
            const nodeX = nodeRect.left - containerRect.left + nodeRect.width / 2;
            const nodeY = nodeRect.top - containerRect.top + nodeRect.height / 2;
            
            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', coreX);
            line.setAttribute('y1', coreY);
            line.setAttribute('x2', nodeX);
            line.setAttribute('y2', nodeY);
            line.setAttribute('stroke', 'rgba(255, 107, 53, 0.3)');
            line.setAttribute('stroke-width', '2');
            
            const animate = document.createElementNS('http://www.w3.org/2000/svg', 'animate');
            animate.setAttribute('attributeName', 'stroke-opacity');
            animate.setAttribute('values', '0.3;1;0.3');
            animate.setAttribute('dur', '2s');
            animate.setAttribute('repeatCount', 'indefinite');
            
            line.appendChild(animate);
            svg.appendChild(line);
        });
        
        brainContainer.insertBefore(svg, brainContainer.firstChild);
    }
}

// ===== 初始化 =====
document.addEventListener('DOMContentLoaded', () => {
    createParticles();
    createNeuralConnections();
    
    // 添加加载完成类
    setTimeout(() => {
        document.body.classList.add('loaded');
    }, 100);
});

// ===== 性能优化：节流函数 =====
function throttle(func, delay) {
    let lastCall = 0;
    return function(...args) {
        const now = new Date().getTime();
        if (now - lastCall < delay) {
            return;
        }
        lastCall = now;
        return func(...args);
    };
}

// 使用节流优化滚动事件
window.addEventListener('scroll', throttle(() => {
    // 检查元素是否在视口中
    const elements = document.querySelectorAll('.feature-card, .pain-card');
    elements.forEach(el => {
        const rect = el.getBoundingClientRect();
        const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
        
        if (isVisible) {
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }
    });
}, 100));

// ===== Easter Egg: Konami Code =====
let konamiCode = [];
const konamiSequence = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];

document.addEventListener('keydown', (e) => {
    konamiCode.push(e.key);
    konamiCode = konamiCode.slice(-konamiSequence.length);
    
    if (konamiCode.join(',') === konamiSequence.join(',')) {
        activateEasterEgg();
    }
});

function activateEasterEgg() {
    const style = document.createElement('style');
    style.textContent = `
        * {
            animation: rainbow 2s linear infinite !important;
        }
        @keyframes rainbow {
            0% { filter: hue-rotate(0deg); }
            100% { filter: hue-rotate(360deg); }
        }
    `;
    document.head.appendChild(style);
    
    setTimeout(() => {
        style.remove();
    }, 5000);
}
