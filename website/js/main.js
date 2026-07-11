// Shuni Landing Page Interactions
document.addEventListener('DOMContentLoaded', () => {
    
    // 1. Smooth scroll for anchor navigation links
    const scrollLinks = document.querySelectorAll('a[href^="#"]');
    scrollLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                e.preventDefault();
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // 2. Scroll fade-in animations
    const faders = document.querySelectorAll('.feature-card, .setup-step');
    const appearOptions = {
        threshold: 0.15,
        rootMargin: "0px 0px -50px 0px"
    };

    const appearOnScroll = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            
            entry.target.classList.add('appear');
            observer.unobserve(entry.target);
        });
    }, appearOptions);

    faders.forEach(fader => {
        // Prepare initial animation states in JS if we want to run animations dynamically
        fader.style.opacity = '0';
        fader.style.transform = 'translateY(20px)';
        fader.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        
        // Define keyframe appearance class in stylesheet or inject inline styles
        appearOnScroll.observe(fader);
    });

    // Watcher to resolve entry animation styling
    const style = document.createElement('style');
    style.innerHTML = `
        .appear {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);
});
