import { Controller } from "@hotwired/stimulus"

// Command for initializing Google API
class GoogleApiInitializerCommand {
  constructor(controller) {
    this.controller = controller;
  }
  
  async execute(retryCount = 0) {
    try {
      this.controller.log('info', 'Initializing Google API');
      
      // First check if the picker is already available
      if (window.google && window.google.picker) {
        this.controller.transitionToState(DocPickerStates.READY);
        return true;
      }
      
      if (!window.gapi) {
        throw new GoogleApiError('Google API (gapi) not found in window');
      }
      
      await new Promise((resolve, reject) => {
        gapi.load('picker', {
          callback: () => {
            this.controller.log('info', 'Picker API loaded successfully');
            resolve();
          },
          onerror: (error) => {
            reject(new GoogleApiError('Failed to load Google Picker API: ' + (error?.message || 'Unknown error')));
          }
        });
      });
      
      // Double check that google.picker is now available
      if (!window.google || !window.google.picker) {
        throw new GoogleApiError("Google Picker API not loaded correctly");
      }
      
      this.controller.transitionToState(DocPickerStates.READY);
      return true;
    } catch (error) {
      // Implement retry logic
      if (retryCount < 2 && !(error instanceof GoogleApiError)) {
        this.controller.log('warn', `API initialization failed, retrying (${retryCount + 1}/2)...`);
        await new Promise(resolve => setTimeout(resolve, 1000));
        return this.execute(retryCount + 1);
      }
      
      this.controller.errorHandler.handleError(error);
      return false;
    }
  }
}

// Command for creating the Google Picker
class PickerCreatorCommand {
  constructor(controller) {
    this.controller = controller;
  }
  
  execute(credentials) {
    try {
      this.controller.log('info', 'Creating document picker');
      this.controller.element.setAttribute('aria-busy', 'true');
      
      // Create a view that shows both folders for navigation and documents for selection
      const docsView = new google.picker.DocsView()
        .setIncludeFolders(true)
        .setSelectFolderEnabled(false)
        .setMimeTypes('application/vnd.google-apps.document,application/vnd.google-apps.folder')
        .setMode(google.picker.DocsViewMode.LIST);
      
      // Check if Google API is ready
      if (!google || !google.picker) {
        console.error('Google Picker API not available at creation time');
        throw new Error('Google Picker API not loaded correctly');
      }
      
      // Verify we have the required credentials
      if (!credentials.oauth_token || credentials.oauth_token === 'null') {
        throw new Error('OAuth token is missing or null');
      }
      if (!credentials.picker_token || credentials.picker_token === 'null') {
        throw new Error('API key (picker token) is missing or null');
      }
      
      const picker = new google.picker.PickerBuilder()
        .addView(docsView)
        .enableFeature(google.picker.Feature.MINE_ONLY)
        .enableFeature(google.picker.Feature.MULTISELECT_ENABLED, true)
        .setSelectableMimeTypes('application/vnd.google-apps.document')
        // The order of these three settings matters for authorization
        .setOAuthToken(credentials.oauth_token)
        .setDeveloperKey(credentials.picker_token)
        .setAppId(credentials.app_id)
        .setTitle('Select multiple student documents')
        .setCallback((data) => {
          console.log('Picker response:', data);
          this.controller.handlePickerResponse(data);
        })
        .build();
    
      picker.setVisible(true);
      return true;
    } catch (error) {
      console.error('Picker creation error:', error);
      this.controller.errorHandler.handleError(
        new PickerError("Failed to create Google Picker: " + error.message)
      );
      return false;
    }
  }
}

// Command for credential fetching
class CredentialsFetcherCommand {
  constructor(controller) {
    this.controller = controller;
  }
  
  async execute() {
    try {
      this.controller.log('info', 'Fetching Google API credentials');
      
      const response = await fetch('/google/credentials', {
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new AuthenticationError('Please sign out and sign back in.');
      }

      const credentials = await response.json();
      return credentials;
    } catch (error) {
      this.controller.errorHandler.handleError(
        error instanceof AuthenticationError ? error : 
        new AuthenticationError('Failed to fetch credentials: ' + error.message)
      );
      return null;
    }
  }
  
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : '';
  }
}

// Value object for selected documents
class SelectedDocument {
  constructor(googleDocData) {
    this.id = googleDocData[google.picker.Document.ID];
    this.title = googleDocData[google.picker.Document.NAME];
    this.url = googleDocData[google.picker.Document.URL];
  }
  
  toJSON() {
    return {
      googleDocId: this.id,
      title: this.title,
      url: this.url
    };
  }
  
  isValid() {
    return Boolean(this.id && this.title);
  }
}

// Document collection validation
class DocumentValidator {
  constructor(maxDocuments) {
    this.maxDocuments = maxDocuments;
  }
  
  validate(documents) {
    if (!documents || !Array.isArray(documents)) {
      return { 
        valid: false, 
        error: new ValidationError('Invalid document data format') 
      };
    }
    
    if (documents.length === 0) {
      return { valid: true, documents: [] };
    }
    
    if (documents.length > this.maxDocuments) {
      return { 
        valid: false, 
        error: new ValidationError(`Maximum of ${this.maxDocuments} documents allowed`) 
      };
    }
    
    // Convert to value objects and validate each document
    const selectedDocuments = documents.map(doc => new SelectedDocument(doc));
    const invalidDocuments = selectedDocuments.filter(doc => !doc.isValid());
    
    if (invalidDocuments.length > 0) {
      return { 
        valid: false, 
        error: new ValidationError('One or more documents are invalid') 
      };
    }
    
    return { valid: true, documents: selectedDocuments };
  }
}

// Error types
class DocPickerError extends Error {
  constructor(message) {
    super(message);
    this.name = this.constructor.name;
  }
}

class GoogleApiError extends DocPickerError {
  constructor(message) {
    super(`Google API Error: ${message}`);
  }
}

class AuthenticationError extends DocPickerError {
  constructor(message) {
    super(`Authentication Error: ${message}`);
  }
}

class PickerError extends DocPickerError {
  constructor(message) {
    super(`Picker Error: ${message}`);
  }
}

class ValidationError extends DocPickerError {
  constructor(message) {
    super(`Validation Error: ${message}`);
  }
}

// Error handler service
class ErrorHandler {
  constructor(controller) {
    this.controller = controller;
  }
  
  handleError(error) {
    this.controller.log('error', `Error: ${error.message}`, { type: error.name });
    
    // Display error message
    if (this.controller.hasErrorTarget) {
      this.controller.errorTarget.textContent = this.formatErrorMessage(error);
      this.controller.errorTarget.classList.add(this.controller.errorClass);
      this.controller.errorTarget.classList.remove(this.controller.hiddenClass);
    }
    
    // Reset UI state
    if (this.controller.hasButtonTarget) {
      this.controller.buttonTarget.disabled = false;
    }
    
    this.controller.element.setAttribute('aria-busy', 'false');
    this.controller.transitionToState(DocPickerStates.ERROR);
  }
  
  formatErrorMessage(error) {
    // Provide user-friendly error messages based on error type
    if (error instanceof GoogleApiError) {
      return 'Could not load Google Drive. Please refresh the page and try again.';
    } else if (error instanceof AuthenticationError) {
      return 'Please sign out and sign back in to access Google Drive.';
    } else if (error instanceof PickerError) {
      return 'Failed to open Google Drive document picker. Please try again.';
    } else if (error instanceof ValidationError) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}

// State machine definitions
const DocPickerStates = {
  INITIAL: 'initial',
  LOADING: 'loading',
  READY: 'ready',
  SELECTING: 'selecting',
  SELECTED: 'selected',
  ERROR: 'error'
};

// Main controller
export default class extends Controller {
  static targets = [
    "button", 
    "documentData", 
    "documentCountText", 
    "error", 
    "instructions", 
    "selectedDocumentsContainer", 
    "documentList", 
    "selectButtonContainer",
    "countError"
  ]
  
  static classes = ["error", "hidden"]
  
  static values = {
    maxDocuments: { type: Number, default: 35 }
  }
  
  initialize() {
    // Setup event names
    this.events = {
      STATE_CHANGED: 'doc-picker:state-changed',
      DOCUMENTS_SELECTED: 'doc-picker:documents-selected',
      API_INITIALIZED: 'doc-picker:api-initialized',
      ERROR_OCCURRED: 'doc-picker:error-occurred'
    };
    
    // Create services
    this.errorHandler = new ErrorHandler(this);
    this.documentValidator = new DocumentValidator(this.maxDocumentsValue);
    
    // Create commands
    this.apiInitializer = new GoogleApiInitializerCommand(this);
    this.credentialsFetcher = new CredentialsFetcherCommand(this);
    this.pickerCreator = new PickerCreatorCommand(this);
    
    // Initialize state
    this.state = DocPickerStates.INITIAL;
    
    // Performance tracking
    this.startTime = performance.now();
  }
  
  connect() {
    console.log('Document picker controller connected');
    this.log('info', 'Document picker controller connected');
    
    if (this.hasInstructionsTarget) {
      this.instructionsTarget.classList.remove(this.hiddenClass);
    }
    
    this.initializeApi();
  }
  
  async initializeApi() {
    this.transitionToState(DocPickerStates.LOADING);
  
    // Try to initialize using existing APIs first
    if (window.google && window.google.picker) {
      this.transitionToState(DocPickerStates.READY);
      return;
    }
  
    // If not already loaded, check if we can load directly
    if (window.gapi) {
      await this.apiInitializer.execute();
    } else {
      this.loadGooglePlatform();
    }
  }
  
  loadGooglePlatform() {
    this.log('info', 'Loading Google Platform API dynamically');
    
    // Add Google Platform API script dynamically if not already loaded
    const script = document.createElement('script');
    script.src = 'https://apis.google.com/js/platform.js';
    script.async = true;
    script.defer = true;
    script.onload = () => {
      this.apiInitializer.execute();
    };
    script.onerror = () => {
      this.errorHandler.handleError(new GoogleApiError('Failed to load Google Platform API'));
    };
    document.head.appendChild(script);
  }
  
  async showPicker() {
    if (this.state !== DocPickerStates.READY) {
      this.log('warn', 'Attempted to show picker when not in READY state');
      return;
    }

    try {
      this.transitionToState(DocPickerStates.SELECTING);
      this.buttonTarget.disabled = true;
      
      const credentials = await this.credentialsFetcher.execute();
      if (!credentials) {
        return; // Error already handled by the command
      }
      
      this.pickerCreator.execute(credentials);
    } catch (error) {
      this.errorHandler.handleError(error);
    }
  }
  
  async handlePickerResponse(data) {
    try {
      if (data.action === 'ERROR') {
        throw new PickerError('Google Drive returned an error');
      }
      
      if (data.action === google.picker.Action.CANCEL || 
          data.action === google.picker.Action.PICKED && (!data.docs || data.docs.length === 0)) {
        this.transitionToState(DocPickerStates.READY);
        this.buttonTarget.disabled = false;
        this.element.setAttribute('aria-busy', 'false');
        return;
      }
      
      // Handle selected documents
      if (data.action === google.picker.Action.PICKED && data.docs && data.docs.length > 0) {
        const docs = data.docs;
        
        // Validate the documents
        const validationResult = this.documentValidator.validate(docs);
        
        if (!validationResult.valid) {
          // Show specific error for max documents
          if (docs.length > this.maxDocumentsValue && this.hasCountErrorTarget) {
            this.countErrorTarget.classList.remove(this.hiddenClass);
            // Hide the regular error if it's showing
            if (this.hasErrorTarget) {
              this.errorTarget.classList.add(this.hiddenClass);
            }
          } else {
            this.errorHandler.handleError(validationResult.error);
          }
          this.transitionToState(DocPickerStates.READY);
          return;
        }
        
        // If we got here, the documents are valid
        if (this.hasCountErrorTarget) {
          this.countErrorTarget.classList.add(this.hiddenClass);
        }
        
        // Process the documents
        this.processSelectedDocuments(validationResult.documents);
      } else {
        // User cancelled or closed without selecting
        this.transitionToState(DocPickerStates.READY);
      }
    } catch (error) {
      this.errorHandler.handleError(error);
    }
  }
  
  processSelectedDocuments(documents) {
    // Convert to JSON for form submission
    const documentData = documents.map(doc => doc.toJSON());
    
    // Store in hidden field for form submission
    if (this.hasDocumentDataTarget) {
      this.documentDataTarget.value = JSON.stringify(documentData);
    }
    
    // Update UI
    this.updateDocumentList(documentData);
    
    // Dispatch event for other components that might be listening
    this.dispatchEvent(this.events.DOCUMENTS_SELECTED, { documents: documentData });
    
    // Update state based on whether documents were selected
    if (documentData.length > 0) {
      this.transitionToState(DocPickerStates.SELECTED);
      
      // Log performance
      this.logPerformance('Document selection');
    } else {
      this.transitionToState(DocPickerStates.READY);
    }
  }
  
  updateDocumentList(documents) {
    // Use targets instead of document.getElementById
    if (!this.hasSelectedDocumentsContainerTarget || !this.hasDocumentListTarget) return;
    
    // Clear current list
    this.documentListTarget.innerHTML = '';
    
    // Update document count
    if (this.hasDocumentCountTextTarget) {
      this.documentCountTextTarget.textContent = documents.length;
    }
    
    // Add each document to the list
    documents.forEach(doc => {
      const listItem = document.createElement('li');
      listItem.className = 'flex items-center text-sm text-gray-600';
      
      // Simple document icon SVG
      listItem.innerHTML = `
        <svg class="mr-2 h-4 w-4 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <a href="${doc.url}" target="_blank" class="text-blue-600 hover:text-blue-800 truncate" title="${doc.title}">${doc.title}</a>
      `;
      
      this.documentListTarget.appendChild(listItem);
    });
    
    // Show/hide the container based on document selection
    if (documents.length > 0) {
      this.selectedDocumentsContainerTarget.classList.remove(this.hiddenClass);
      
      // Show/hide instructions based on document selection
      if (this.hasInstructionsTarget) {
        this.instructionsTarget.classList.add(this.hiddenClass);
      }
      
      // Show/hide the initial 'Select student work' button container
      if (this.hasSelectButtonContainerTarget) {
        this.selectButtonContainerTarget.classList.add(this.hiddenClass);
      }
    } else {
      this.selectedDocumentsContainerTarget.classList.add(this.hiddenClass);
      
      // Show instructions again
      if (this.hasInstructionsTarget) {
        this.instructionsTarget.classList.remove(this.hiddenClass);
      }
      
      // Show the button container again
      if (this.hasSelectButtonContainerTarget) {
        this.selectButtonContainerTarget.classList.remove(this.hiddenClass);
      }
    }
    
    // Update accessibility info
    this.element.setAttribute('aria-busy', 'false');
    this.element.setAttribute('aria-label', `${documents.length} documents selected`);
  }
  
  transitionToState(newState) {
    if (this.state === newState) return;
    
    const previousState = this.state;
    this.state = newState;
    this.log('info', `State transition: ${previousState} -> ${newState}`);
    
    // Update UI based on new state
    this.updateUiForState(newState);
    
    // Dispatch event
    this.dispatchEvent(this.events.STATE_CHANGED, { 
      previousState, 
      currentState: newState 
    });
  }
  
  updateUiForState(state) {
    // Enable/disable buttons based on state
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = ![DocPickerStates.READY, DocPickerStates.SELECTED].includes(state);
    }
    
    // Add/remove classes to reflect current state
    this.element.setAttribute('data-state', state);
    
    // Clear error display when transitioning to a non-error state
    if (state !== DocPickerStates.ERROR && this.hasErrorTarget) {
      this.errorTarget.classList.add(this.hiddenClass);
    }
  }
  
  // Helper method to dispatch custom events
  dispatchEvent(name, detail) {
    this.element.dispatchEvent(new CustomEvent(name, { detail, bubbles: true }));
  }
  
  // Logging helper
  log(level, message, data = {}) {
    console[level](`DocPicker: ${message}`, data);
  }
  
  // Performance logging
  logPerformance(operation) {
    const duration = performance.now() - this.startTime;
    this.log('info', `${operation} completed in ${duration.toFixed(2)}ms`);
  }
}
