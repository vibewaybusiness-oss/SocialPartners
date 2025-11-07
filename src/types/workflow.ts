// =========================
// WORKFLOW SYSTEM TYPES
// =========================

export interface WorkflowContext {
  projectId?: string | null;
  setProjectId?: (id: string) => void;
  messages: Message[];
  setMessages: (updater: (prev: Message[]) => Message[]) => void;
  addAssistantMessageWithDelay: (message: Omit<Message, 'id' | 'timestamp'>, delay?: number) => void;
  prompt: string;
  setPrompt: (prompt: string) => void;
  inputEnabled: boolean;
  setInputEnabled: (enabled: boolean) => void;
  fileInputEnabled: boolean;
  setFileInputEnabled: (enabled: boolean) => void;
  fileInputRef: React.RefObject<HTMLInputElement>;
  uploadedImages: File[];
  setUploadedImages: (updater: (prev: File[]) => File[]) => void;
  uploadedAudio: File[];
  setUploadedAudio: (updater: (prev: File[]) => File[]) => void;
  isGenerating: boolean;
  setIsGenerating: (generating: boolean) => void;
  toast: (options: ToastOptions) => void;
}

export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  files?: {
    images: (File | { name: string; size?: number; type?: string; fileId?: string; url?: string })[];
    audio: (File | { name: string; size?: number; type?: string; fileId?: string; url?: string })[];
  };
  actionButtons?: ActionButton[];
  enableFileInput?: boolean;
  enablePromptInput?: boolean;
  agent?: {
    validation: boolean;
    output: string;
    parsed?: any;
    stepId?: string;
    nodeKey?: string;
  };
}

export interface ActionButton {
  label?: string;
  icon?: React.ReactNode;
  variant?: 'default' | 'outline' | 'ghost' | 'destructive';
  size?: 'sm' | 'md' | 'lg' | 'icon';
  className?: string;
  disabled?: boolean;
  onClick: () => void;
}

export interface ToastOptions {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
  duration?: number;
}

// =========================
// DECLARATIVE WORKFLOW STRUCTURE
// =========================

export interface WorkflowInput {
  type: 'text' | 'image' | 'video' | 'audio';
  required: boolean;
  multiple?: boolean;
  accept?: string;
  maxFiles?: number;
  placeholder?: string;
  label?: string;
  validation?: {
    minLength?: number;
    maxLength?: number;
    pattern?: string;
  };
}

export interface WorkflowOutput {
  type: 'text' | 'image' | 'video' | 'audio' | 's3_file';
  s3Key?: string;
  s3Path?: string;
  contentType?: string;
  saveConfig?: {
    key: string;
    type: 'string' | 'object' | 'array' | 'dict';
    backendKey: string;
    backendType: 'list' | 'dict';
    backendSubkey?: string;
  };
}

export interface TransitionRule {
  condition?: {
    type: 'returnValue' | 'dataKey' | 'function';
    value?: any;
    key?: string;
    function?: string;
  };
  nextStep: string;
}

export interface WorkflowStep {
  stepId: string;
  stepNumber: number;
  type: 'text' | 'node' | 'processor';
  content?: string;
  nodeKey?: string;
  processorKey?: string;
  optional?: boolean;
  requires?: string[];
  transitions?: Array<{
    condition?: {
      type: string;
      value?: any;
    };
    nextStep?: string;
  }>;
  defaultNextStep?: string | null;
  nextStep?: string | null;
}

export interface WorkflowConfig {
  id: string;
  name: string;
  description: string;
  version: string;
  globalSettings?: {
    autoSave: boolean;
    errorHandling: 'stop' | 'continue' | 'retry';
    timeout: number;
  };
  flow: WorkflowStep[];
  metadata?: {
    created: string;
    updated: string;
    author: string;
  };
}

export interface LegacyWorkflowStep {
  id: string;
  stepNumber: number;
  assistantMessage?: {
    content: string;
    showDelay?: number;
    enableFileInput?: boolean;
    enablePromptInput?: boolean;
  };
  inputs?: WorkflowInput[];
  outputs?: WorkflowOutput[];
  bricks: BrickConfig[];
  transitions?: TransitionRule[];
  nextStep?: string;
  projectData?: {
    key: string;
    type: 'string' | 'object' | 'array' | 'dict';
    backendKey: string;
    backendType: 'list' | 'dict';
    backendSubkey?: string;
    source?: 'user_input' | 'brick_output' | 'static' | 'workflow_data';
    sourceKey?: string;
  }[];
  autoSave?: boolean;
}

export interface LegacyWorkflowConfig {
  id: string;
  name: string;
  description: string;
  initialStep: string;
  steps: Record<string, LegacyWorkflowStep>;
  globalSettings?: {
    autoSave: boolean;
    errorHandling: 'continue' | 'stop' | 'retry';
    timeout: number;
  };
}

export interface NodeDefinition {
  id: string;
  name: string;
  type: 'input' | 'output' | 'generator';
  category: string;
  description: string;
  file_input: boolean;
  prompt_input: boolean;
  ai_button: boolean;
  inputs: Array<{
    key: string;
    type: string;
    source?: string;
    required: boolean;
  }>;
  outputs: Array<{
    key: string;
    type: string;
    dataType: string;
    description: string;
  }>;
  parameters?: Record<string, any>;
  validation?: {
    required?: boolean;
    message?: string;
    minLength?: number;
    maxLength?: number;
    pattern?: string;
    custom?: (value: any) => boolean | string;
  };
  config?: {
    backendKey: string;
    backendType: string;
    saveKey: string;
    backendSubkey?: string;
  };
}

export interface ProcessorDefinition {
  id: string;
  name: string;
  type: 'processor';
  description: string;
  flow: Array<{
    stepId: string;
    type: 'text' | 'node' | 'util' | 'choice';
    content?: string;
    nodeKey?: string;
    utilKey?: string;
    nextStep?: string;
    defaultNextStep?: string;
    advance?: 'auto' | 'non-auto' | 'user-defined';
    transitions?: Array<{
      condition?: {
        type: string;
        value?: any;
      };
      nextStep?: string;
    }>;
    choices?: Array<{
      label: string;
      value: string;
      nextStep: string;
    }>;
    params?: Record<string, any>;
    onSuccess?: string;
    onError?: {
      nextStep?: string;
      message?: string;
    };
    background?: boolean;
    agent?: boolean;
    agentPrompt?: string;
    editable?: boolean;
  }>;
  inputs: Array<{
    key: string;
    type: string;
    source?: string;
    required: boolean;
  }>;
  outputs: Array<{
    key: string;
    type: string;
    description: string;
  }>;
}

export interface UtilDefinition {
  id: string;
  name: string;
  type: 'util';
  category: 'validation' | 'storage' | 'infrastructure' | 'ai';
  description: string;
  background: boolean;
  parameters: {
    endpoint: string;
    method: string;
    params?: Record<string, any>;
  };
  inputs: Array<{
    key: string;
    type: string;
    source?: string;
    required: boolean;
  }>;
  outputs: Array<{
    key: string;
    type: string;
    description: string;
  }>;
}

export interface WorkflowHelpers {
  setData: (updater: (prev: any) => any) => void;
  setStep: (step: string) => void | Promise<void>;
  saveState: (projectId: string | null | undefined) => Promise<void>;
  toast: (options: ToastOptions) => void;
  projectId?: string | null;
}

// =========================
// BRICK CONFIGURATION TYPES
// =========================

export type BrickType = 'llm' | 'user_input' | 'api_call' | 'background';

export interface BaseBrickConfig {
  id: string;
  type: BrickType;
  enabled?: boolean;
  validation?: {
    required?: boolean;
    custom?: (value: any) => boolean | string;
  };
}

export interface LLMBrickConfig extends BaseBrickConfig {
  type: 'llm';
  buttons: Array<{
    label: string;
    action: string;
    returnValue: any;
    variant?: 'default' | 'outline' | 'ghost';
    userMessage?: string;
    nextStep?: string; // Optional explicit next step for this button
    modal?: string; // Modal component name (e.g., "GenreSelector")
    modalProps?: Record<string, any>; // Props to pass to the modal
  }>;
  activatePrompt: boolean;
  activateFileUpload: boolean;
  fileTypes?: string[];
  prompt: {
    placeholder: string;
    editable: boolean;
    confirmRequired: boolean;
  };
  assistantMessage?: {
    content: string;
    showDelay?: number;
    enableFileInput?: boolean;
    enablePromptInput?: boolean;
  };
}

export interface UserInputBrickConfig extends BaseBrickConfig {
  type: 'user_input';
  inputType: 'text' | 'file' | 'multiselect' | 'select' | 'checkbox' | 'radio';
  saveConfig: {
    key: string;
    type: 'string' | 'object' | 'array' | 'dict';
    backendKey: string;
    backendType: 'list' | 'dict';
    backendSubkey?: string;
  };
  validation?: {
    required: boolean;
    minLength?: number;
    maxLength?: number;
    pattern?: string;
    custom?: (value: any) => boolean | string;
  };
  options?: Array<{
    label: string;
    value: any;
    disabled?: boolean;
  }>;
  placeholder?: string;
  label?: string;
  accept?: string;
  multiple?: boolean;
  maxFiles?: number;
  // Transition after input is submitted
  onComplete?: {
    nextStep?: string;
    condition?: {
      type: 'dataKey' | 'function';
      key?: string;
      value?: any;
      function?: string;
    };
  };
}

export interface APICallBrickConfig extends BaseBrickConfig {
  type: 'api_call';
  endpoint: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  payload: {
    source: 'workflow_data' | 'user_input' | 'static';
    mapping?: Record<string, string>;
    staticData?: any;
  };
  response?: {
    saveConfig?: {
      key: string;
      type: 'string' | 'object' | 'array' | 'dict';
      backendKey: string;
      backendType: 'list' | 'dict';
      backendSubkey?: string;
    };
    s3Output?: {
      key: string;
      path: string;
      contentType: string;
      saveConfig?: {
        key: string;
        type: 'string' | 'object' | 'array' | 'dict';
        backendKey: string;
        backendType: 'list' | 'dict';
      };
    };
    transform?: (response: any) => any;
  };
  headers?: Record<string, string>;
  timeout?: number;
  retries?: number;
  onSuccess?: {
    nextStep?: string;
    message?: string;
  };
  onError?: {
    nextStep?: string;
    message?: string;
  };
}

export interface BackgroundBrickConfig extends BaseBrickConfig {
  type: 'background';
  trigger: 'immediate' | 'on_step_enter' | 'on_condition';
  condition?: (data: any) => boolean;
  action: {
    id?: string;
    type: 'api_call' | 'file_processing' | 'ai_generation';
    endpoint?: string;
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
    payload?: {
      source: 'workflow_data' | 'user_input' | 'static';
      mapping?: Record<string, string>;
      staticData?: any;
    };
    config?: any;
  };
  onComplete?: {
    nextStep?: string;
    message?: string;
    dataUpdate?: Record<string, any>;
  };
}

export interface FileProcessingConfig {
  type: 'file_processing';
  operation: 'upload' | 'download' | 'transform' | 'analyze';
  config: {
    s3Key?: string;
    backendKey: string;
    backendType: 'list' | 'dict';
    backendSubkey?: string;
    transform?: (file: File) => any;
  };
}

export interface AIGenerationConfig {
  type: 'ai_generation';
  model: string;
  parameters: Record<string, any>;
  inputMapping: Record<string, string>;
  outputMapping: {
    saveKey: string;
    saveType: 'string' | 'object' | 'array' | 'dict';
  };
}

export type BrickConfig = 
  | LLMBrickConfig 
  | UserInputBrickConfig 
  | APICallBrickConfig 
  | BackgroundBrickConfig;

// =========================
// BRICK CONTEXT TYPES
// =========================

export interface BrickContext {
  workflowData: Record<string, any>;
  setData: (updater: (prev: any) => any) => void;
  setStep: (stepId: string) => void;
  saveState: (projectId: string) => Promise<void>;
  toast: (options: ToastOptions) => void;
  projectId?: string;
}

export interface BrickProps<T = any> {
  config: BrickConfig;
  context: BrickContext;
  onComplete: (value: T) => void;
  onError: (error: Error) => void;
}

// =========================
// WORKFLOW EXECUTION TYPES
// =========================

export interface WorkflowExecutionState {
  currentStep: string;
  workflowData: Record<string, any>;
  isExecuting: boolean;
  error?: Error;
  completedSteps: string[];
}

export interface WorkflowExecutionResult {
  success: boolean;
  data?: any;
  error?: Error;
  nextStep?: string;
}
