// Azzurro Tech Website JavaScript

// Global state
let currentUser = null;
let isLoading = false;

// Initialize the website
function initWebsite() {
    setupEventListeners();
    setupScrollspy();
    setupModals();
    loadComponentData();
    checkUrlParams();
}

// Setup event listeners
function setupEventListeners() {
    // Navigation links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = this.getAttribute('href');
            scrollToSection(target.substring(1));

            // Update active state
            document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // Mobile menu toggle
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    if (mobileToggle) {
        mobileToggle.addEventListener('click', function() {
            toggleMobileMenu();
        });
    }

    // Modal close buttons
    document.querySelectorAll('.close').forEach(closeBtn => {
        closeBtn.addEventListener('click', function() {
            const modal = this.closest('.modal');
            closeModal(modal.id.replace('-modal', ''));
        });
    });

    // Modal overlay clicks
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', function(e) {
            if (e.target === modal) {
                closeModal(modal.id.replace('-modal', ''));
            }
        });
    });

    // Form submissions
    document.querySelectorAll('form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            handleFormSubmit(this);
        });
    });

    // Button clicks for services and components
    document.querySelectorAll('[onclick^="useService"]').forEach(button => {
        button.addEventListener('click', function() {
            const service = this.getAttribute('onclick').match(/'([^']+)'/)[1];
            useService(service);
        });
    });

    document.querySelectorAll('[onclick^="useComponent"]').forEach(button => {
        button.addEventListener('click', function() {
            const component = this.getAttribute('onclick').match(/'([^']+)'/)[1];
            useComponent(component);
        });
i    });

    // Service cards hover effects
    document.querySelectorAll('.service-card').forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-8px)';
        });

        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });

    // Component cards hover effects
    document.querySelectorAll('.component-card').forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-8px)';
        });

        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });

    // Pricing cards hover effects
    document.querySelectorAll('.pricing-card').forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.boxShadow = '0 12px 30px rgba(0, 102, 204, 0.2)';
        });

        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = 'none';
        });
    });

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', function(e) {
            if (this.hostname === window.location.hostname && this.pathname === window.location.pathname) {
                e.preventDefault();
                const target = this.getAttribute('href');
                if (target.startsWith('#')) {
                    scrollToSection(target.substring(1));
                }
            }
        });
    });

    // Scroll to top button (if exists)
    let scrollTopBtn = document.getElementById('scroll-top');
    if (!scrollTopBtn) {
        scrollTopBtn = document.createElement('button');
        scrollTopBtn.id = 'scroll-top';
        scrollTopBtn.innerHTML = '↑';
        scrollTopBtn.style.cssText = `
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            background: var(--primary-color);
            color: white;
            border: none;
            cursor: pointer;
            font-size: 20px;
            font-weight: bold;
            z-index: 1000;
            display: none;
            transition: var(--transition);
        `;
        document.body.appendChild(scrollTopBtn);

        scrollTopBtn.addEventListener('click', function() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }
}

// Scroll spy - update active navigation on scroll
function setupScrollspy() {
    const sections = document.querySelectorAll('section[id]');

    function updateActiveNav() {
        let current = '';
        const scrollPosition = window.scrollY + 100;

        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;

            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                current = section.getAttribute('id');
            }
        });

        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === '#' + current) {
                link.classList.add('active');
            }
        });
    }

    window.addEventListener('scroll', updateActiveNav);
    updateActiveNav(); // Initial call
}

// Setup modals
function setupModals() {
    // Close modals with ESC key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeAllModals();
        }
    });
}

// Toggle mobile menu
function toggleMobileMenu() {
    const navLinks = document.querySelector('.nav-links');
    const toggle = document.querySelector('.mobile-menu-toggle');

    if (navLinks.style.display === 'flex') {
        navLinks.style.display = 'none';
        toggle.innerHTML = '<span></span><span></span><span></span>';
    } else {
        navLinks.style.display = 'flex';
        navLinks.style.flexDirection = 'column';
        toggle.innerHTML = '×';
        toggle.style.fontSize = '24px';
    }
}

// Show modal
function showModal(modalId) {
    const modal = document.getElementById(modalId + '-modal');
    if (modal) {
        modal.style.display = 'flex';
        modal.classList.add('show');
        modal.focus();

        // Clear forms
        if (modalId === 'login') {
            document.getElementById('login-form')?.reset();
        } else if (modalId === 'signup') {
            document.getElementById('signup-form')?.reset();
        }
    }
}

// Close modal
function closeModal(modalId) {
    const modal = document.getElementById(modalId + '-modal');
    if (modal) {
        modal.style.display = 'none';
        modal.classList.remove('show');
    }
}

// Close all modals
function closeAllModals() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.style.display = 'none';
        modal.classList.remove('show');
    });
}

// Show login modal
function showLoginModal() {
    closeAllModals();
    showModal('login');
}

// Show signup modal
function showSignupModal() {
    closeAllModals();
    showModal('signup');
}

// Show demo modal
function showDemoModal() {
    closeAllModals();
    showModal('demo');
}

// Scroll to section
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        const offset = 80; // Header offset
        const elementPosition = section.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - offset;

        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
    }
}

// Use service
function useService(serviceName) {
    closeAllModals();
    console.log(`Using service: ${serviceName}`);

    // Show notification
    showNotification(`${serviceName} service details will be displayed here.`, 'info');

    // Scroll to contact section for more info
    setTimeout(() => {
        scrollToSection('contact');
        document.getElementById('service').value = serviceName;
    }, 500);
}

// Use component
function useComponent(componentName) {
    closeAllModals();
    console.log(`Using component: ${componentName}`);

    // Show notification
    showNotification(`${componentName} component details will be displayed here.`, 'info');

    // Show demo modal
    showDemoModal();
}

// Select pricing plan
function selectPlan(planName) {
    closeAllModals();
    showNotification(`${planName} plan selected! Redirecting to checkout...`, 'success');
    console.log(`Selected plan: ${planName}`);

    // In real implementation, redirect to payment page
    setTimeout(() => {
        showNotification('Payment form would open here.', 'info');
    }, 1000);
}

// Handle contact form submission
function handleContactSubmit(event) {
    event.preventDefault();

    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    showNotification('Sending your message...', 'info');

    // Simulate form submission
    setTimeout(() => {
        showNotification('Thank you! Your message has been sent successfully. We will contact you soon.', 'success');
        form.reset();
        closeAllModals();
    }, 2000);
}

// Handle login form submission
function handleLogin(event) {
    event.preventDefault();

    const form = event.target;
    const email = form.querySelector('input[type="email"]').value;
    const password = form.querySelector('input[type="password"]').value;

    if (!email || !password) {
        showNotification('Please fill in all fields.', 'error');
        return;
    }

    showNotification('Signing in...', 'info');

    // Simulate login
    setTimeout(() => {
        currentUser = { email: email };
        showNotification('Successfully logged in!', 'success');
        closeModal('login');
        updateUIForLoggedInUser();
    }, 1500);
}

// Handle signup form submission
function handleSignup(event) {
    event.preventDefault();

    const form = event.target;
    const name = form.querySelectorAll('input[type="text"]')[0].value;
    const email = form.querySelectorAll('input[type="email"]')[0].value;
    const password = form.querySelectorAll('input[type="password"]')[0].value;
    const plan = form.querySelector('select').value;

    if (!name || !email || !password || !plan) {
        showNotification('Please fill in all fields.', 'error');
        return;
    }

    showNotification('Creating your account...', 'info');

    // Simulate signup
    setTimeout(() => {
        currentUser = { name: name, email: email, plan: plan };
        showNotification('Account created successfully!', 'success');
        closeModal('signup');
        updateUIForLoggedInUser();
    }, 1500);
}

// Update UI for logged in user
function updateUIForLoggedInUser() {
    const authButtons = document.querySelector('.auth-buttons');
    if (authButtons) {
        authButtons.innerHTML = `
            <div class="user-menu">
                <button class="btn btn-outline" onclick="showUserMenu()">Welcome, ${currentUser?.name || currentUser?.email}! ▼</button>
                <div class="user-dropdown" id="user-dropdown" style="display: none;">
                    <a href="#" onclick="viewAccount()">My Account</a>
                    <a href="#" onclick="viewBilling()">Billing</a>
                    <a href="#" onclick="viewSettings()">Settings</a>
                    <a href="#" onclick="logoutUser()">Log Out</a>
                </div>
            </div>
        `;
    }
}

// Show user menu
function showUserMenu() {
    const dropdown = document.getElementById('user-dropdown');
    if (dropdown) {
        dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
    }
}

// View account
function viewAccount() {
    closeAllModals();
    showNotification('Account details would be shown here.', 'info');
}

// View billing
function viewBilling() {
    closeAllModals();
    showNotification('Billing history and payment details would be shown here.', 'info');
}

// View settings
function viewSettings() {
    closeAllModals();
    showNotification('Settings would be shown here.', 'info');
}

// Logout user
function logoutUser() {
    currentUser = null;
    closeAllModals();
    showNotification('Successfully logged out.', 'success');

    // Reset auth buttons
    const authButtons = document.querySelector('.auth-buttons');
    if (authButtons) {
        authButtons.innerHTML = `
            <button class="btn btn-secondary" onclick="showLoginModal()">Sign In</button>
            <button class="btn btn-primary" onclick="showSignupModal()">Get Started</button>
        `;
    }
}

// Load component data
function loadComponentData() {
    // Load VENI web component example
    loadVENIComponent();

    // Load VIDI chart example
    loadVIDIExample();
}

// Load VENI component example
function loadVENIComponent() {
    const veniContainer = document.createElement('div');
    veniContainer.innerHTML = `
        <div class="component-example">
            <h4>VENI Web Component</h4>
            <p>This demonstrates how VENI web components can be embedded directly in your pages without any servers.</p>
            <button class="btn btn-primary" onclick="demoVENI()">Demo VENI Component</button>
        </div>
    `;

    console.log('VENI component loaded:', veniContainer);
}

// Load VIDI example
function loadVIDIExample() {
    const vidiContainer = document.createElement('div');
    vidiContainer.innerHTML = `
        <div class="component-example">
            <h4>VIDI Data Visualization</h4>
            <p>This demonstrates VIDI's data visualization and management capabilities with real-time charts and filters.</p>
            <button class="btn btn-primary" onclick="demoVIDI()">Demo VIDI Component</button>
        </div>
    `;

    console.log('VIDI component loaded:', vidiContainer);
}

// Demo VENI component
function demoVENI() {
    showNotification('VENI component demo would show web component discovery and generation here.', 'info');
}

// Demo VIDI component
function demoVIDI() {
    showNotification('VIDI component demo would show data visualization and management here.', 'info');
}

// Check URL parameters
function checkUrlParams() {
    const urlParams = new URLSearchParams(window.location.search);

    if (urlParams.get('demo') === 'true') {
        showDemoModal();
    }

    if (urlParams.get('service')) {
        const service = urlParams.get('service');
        scrollToSection('services');
        setTimeout(() => {
            useService(service);
        }, 500);
    }
}

// Show notification
function showNotification(message, type = 'info') {
    // Remove existing notifications
    document.querySelectorAll('.notification').forEach(n => n.remove());

    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        padding: 1rem 1.5rem;
        border-radius: var(--border-radius);
        color: white;
        font-weight: 600;
        z-index: 2000;
        animation: slideInRight 0.3s ease;
        ${type === 'success' ? 'background: var(--success-color);' : ''}
        ${type === 'error' ? 'background: var(--danger-color);' : ''}
        ${type === 'warning' ? 'background: var(--warning-color); color: #333;' : ''}
        ${type === 'info' ? 'background: var(--primary-color);' : ''}
    `;
    notification.textContent = message;

    document.body.appendChild(notification);

    // Auto remove after 3 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.style.animation = 'slideOutRight 0.3s ease';
            setTimeout(() => {
                notification.remove();
            }, 300);
        }
    }, 3000);
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }

    @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(100%); opacity: 0; }
    }
`;
document.head.appendChild(style);

// Handle window resize
let resizeTimeout;
window.addEventListener('resize', function() {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(function() {
        // Update any responsive elements
        updateScrollTopButton();
    }, 250);
});

// Update scroll top button visibility
function updateScrollTopButton() {
    const scrollTopBtn = document.getElementById('scroll-top');
    if (scrollTopBtn) {
        if (window.pageYOffset > 500) {
            scrollTopBtn.style.display = 'block';
        } else {
            scrollTopBtn.style.display = 'none';
        }
    }
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initWebsite);
} else {
    initWebsite();
}

// Global functions for HTML onclick handlers
window.showLoginModal = showLoginModal;
window.showSignupModal = showSignupModal;
window.showDemoModal = showDemoModal;
window.scrollToSection = scrollToSection;
window.useService = useService;
window.useComponent = useComponent;
window.selectPlan = selectPlan;
window.handleContactSubmit = handleContactSubmit;
window.closeAllModals = closeAllModals;
window.demoVENI = demoVENI;
window.demoVIDI = demoVIDI;

// Enhanced Emperor42 Integration System
const emperor42System = {
  // Initialize all Emperor42 projects
  init: function() {
    // Initialize VIDI with enhanced analytics
    if (typeof Vidi !== 'undefined') {
      this.vidi = new Vidi({
        dataSource: '/api/website-analytics',
        enableCORS: true,
        pagination: { pageSize: 12, enabled: true },
        encryptionKey: null,
        cookieSettings: { secure: false, httpOnly: true }
      });
      this.vidi.init();
    }

    // Initialize VICI with website content management
    if (typeof Vici !== 'undefined') {
      this.vici = new Vici({
        autoSave: true,
        saveInterval: 3000,
        user: { id: 'admin', username: 'Website Admin' },
        permissions: {
          canCreate: true,
          canRead: true,
          canUpdate: true,
          canDelete: true
        },
        auditLog: true,
        encryptionKey: null
      });
      this.vici.init();
    }

    // Initialize VINI with workflow system
    if (typeof Vini !== 'undefined') {
      this.vini = new Vini({
        autoStart: false,
        debugMode: false,
        serverEndpoint: null,
        encryptionKey: null,
        validationSchema: {
          requiredFields: ['name', 'email', 'message'],
          minLength: 5,
          maxLength: 500
        }
      });
      this.vini.init();
    }

    // Setup live component scanning
    this.setupLiveComponentScanning();

    // Setup website integration
    this.setupWebsiteIntegration();
  },

  // Setup live component scanning using VENI
  setupLiveComponentScanning: function() {
    setTimeout(() => {
      const componentCount = 15; // Simulated component count
      console.log(`VENI Component Scanner found ${componentCount} components`);

      this.updateComponentStats('veni', componentCount, 'Live');
    }, 1000);
  },

  // Setup website integration with VICI and VINI
  setupWebsiteIntegration: function() {
    // Setup VICI website content management
    this.setupVICIWebsiteManagement();

    // Setup VINI website workflows
    this.setupVINIWebsiteWorkflows();

    // Setup VIDI analytics for website interactions
    this.setupVIDIAnalytics();
  },

  // Setup VICI website content management
  setupVICIWebsiteManagement: function() {
    if (!this.vici) return;

    const websitePages = [
      { id: 'home', title: 'Home', status: 'published', version: '1.2.3' },
      { id: 'services', title: 'Services', status: 'published', version: '1.2.1' },
      { id: 'components', title: 'Components', status: 'published', version: '1.2.2' },
      { id: 'pricing', title: 'Pricing', status: 'published', version: '1.2.0' },
      { id: 'contact', title: 'Contact', status: 'published', version: '1.1.9' }
    ];

    // Create website content management using VICI
    websitePages.forEach(page => {
      if (!this.vici.getPage(page.id)) {
        this.vici.createPage({
          title: page.title,
          slug: page.id,
          content: `Content for ${page.title} page`,
          html: `<h1>${page.title}</h1><p>Website content for ${page.title} section.</p>`,
          css: `.page-${page.id} { background: var(--background-primary); }`,
          createdBy: 'admin',
          updatedBy: 'admin',
          status: page.status,
          version: page.version
        });
      }
    });
  },

  // Setup VINI website workflows
  setupVINIWebsiteWorkflows: function() {
    if (!this.vini) return;

    // Create user registration workflow
    if (!this.vini.getWorkflowByName('User Registration')) {
      this.vini.createWorkflow('User Registration', [
        {
          id: 'step-1',
          name: 'Website Visit',
          type: 'trigger',
          description: 'User visits Azzurro Tech website'
        },
        {
          id: 'step-2',
          name: 'Navigation to Registration',
          type: 'action',
          description: 'User clicks "Get Started" button'
        },
        {
          id: 'step-3',
          name: 'Form Completion',
          type: 'input',
          description: 'User fills registration form'
        },
        {
          id: 'step-4',
          name: 'Email Verification',
          type: 'validation',
          description: 'User verifies email address'
        },
        {
          id: 'step-5',
          name: 'Account Setup',
          type: 'completion',
          description: 'User completes account setup'
        }
      ]);
    }

    // Create component service request workflow
    if (!this.vini.getWorkflowByName('Component Service Request')) {
      this.vini.createWorkflow('Component Service Request', [
        {
          id: 'step-1',
          name: 'Component Selection',
          type: 'trigger',
          description: 'User selects an Emperor42 component'
        },
        {
          id: 'step-2',
          name: 'Service Request',
          type: 'action',
          description: 'User requests component service'
        },
        {
          id: 'step-3',
          name: 'Details Submission',
          type: 'input',
          description: 'User provides component-specific details'
        },
        {
          id: 'step-4',
          name: 'Request Submission',
          type: 'completion',
          description: 'User submits the service request'
        }
      ]);
    }
  },

  // Setup VIDI analytics for website interactions
  setupVIDIAnalytics: function() {
    if (!this.vidi) return;

    // Track website component interactions
    setInterval(() => {
      this.trackComponentInteractions();
    }, 5000);
  },

  // Track component interactions
  trackComponentInteractions: function() {
    const interactions = [
      { component: 'veni', action: 'card-click', category: 'component-interaction', value: 1 },
      { component: 'vidi', action: 'analytics-view', category: 'component-interaction', value: 1 },
      { component: 'vici', action: 'page-edit', category: 'component-interaction', value: 1 },
      { component: 'vini', action: 'workflow-start', category: 'component-interaction', value: 1 }
    ];

    interactions.forEach(interaction => {
      this.vidi.addData(interaction);
    });
  },

  // Update component statistics display
  updateComponentStats: function(component, count, status) {
    const element = document.getElementById(`${component}-count`);
    if (element) {
      element.textContent = count;
    }

    const statusElement = document.querySelector(`.${component}-status`);
    if (statusElement) {
      statusElement.textContent = status;
      statusElement.style.color = status === 'Live' ? '#28a745' : '#ffc107';
    }
  },

  // Update VIDI analytics display
  updateVidiaDisplay: function() {
    if (!this.vidi) return;

    const data = this.vidi.getPaginatedData(1, { category: 'component-interaction' });

    const totalInteractions = data.length;
    const activeUsers = [...new Set(data.map(d => d.component))].length;

    document.getElementById('component-interactions').textContent = totalInteractions;
    document.getElementById('active-users').textContent = activeUsers;
  }
};

// Global function to start Emperor42 integrations
const startEmperor42Integrations = function() {
  emperor42System.init();
  showNotification('Emperor42 Integration System Initialized', 'success');
};

// Global functions for VICI and VINI
window.showVICIAdmin = function() {
  closeAllModals();
  showNotification('VICI Admin Interface would be displayed here.', 'info');
};

window.showVINIWorkflowBuilder = function() {
  closeAllModals();
  showNotification('VINI Workflow Builder would be displayed here.', 'info');
};

window.startLiveComponentScan = function() {
  emperor42System.updateComponentStats('veni', Math.floor(Math.random() * 20) + 5, 'Live');
  showNotification('Live component scan started successfully!', 'success');
};

window.startLiveAnalytics = function() {
  emperor42System.updateVidiaDisplay();
  showNotification('Live analytics dashboard updated!', 'success');
};

// Initialize Emperor42 integrations when website loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() {
    // Start Emperor42 integrations after a short delay
    setTimeout(() => {
      startEmperor42Integrations();
    }, 2000);
  });
} else {
  // Website already loaded, initialize quickly
  setTimeout(() => {
    startEmperor42Integrations();
  }, 2000);
}