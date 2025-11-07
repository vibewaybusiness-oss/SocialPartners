import { useState, useEffect, useCallback, useRef } from 'react';
import type { WorkflowContext, Message, WorkflowConfig, WorkflowStep, ProcessorDefinition } from '@/types/workflow';

interface UseWorkflowProcessorOptions {
  workflowId: string;
  context: WorkflowContext;
  enabled?: boolean;
}

interface ActiveProcessorState {
  processor: ProcessorDefinition;
  currentStepIndex: number;
  processedSteps: Set<string>;
  currentNodeData?: any;
  nodeOutputs?: Map<string, any>;
}

export function useWorkflowProcessor({
  workflowId,
  context,
  enabled = true
}: UseWorkflowProcessorOptions) {
  const [workflow, setWorkflow] = useState<WorkflowConfig | null>(null);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [processorNodeUpdate, setProcessorNodeUpdate] = useState(0);

  const processedSteps = useRef(new Set<string>());
  const activeProcessor = useRef<ActiveProcessorState | null>(null);

  const fetchData = async (url: string) => {
    try {
      const res = await fetch(`${url}?_t=${Date.now()}`, {
        cache: 'no-store',
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      });
      return res.ok ? await res.json() : null;
    } catch {
      return null;
    }
  };

  useEffect(() => {
    if (!enabled || !workflowId) {
      console.log('Workflow processor disabled or no workflowId:', { enabled, workflowId });
      return;
    }

    const load = async () => {
      setLoading(true);
      setError(null);
      console.log('Loading workflow:', workflowId);
      try {
        const data = await fetchData(`/api/v1/chatbot/workflows/${workflowId}`);
        if (!data) {
          console.error('Failed to load workflow - no data returned');
          throw new Error('Failed to load workflow');
        }
        
        console.log('Workflow loaded successfully:', data.id, 'with', data.flow?.length, 'steps');
        setWorkflow(data);
        setCurrentStepIndex(0);
        processedSteps.current.clear();
        activeProcessor.current = null;
        setProcessorNodeUpdate(0);
      } catch (err) {
        console.error('Error loading workflow:', err);
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [workflowId, enabled]);

  const goToStep = useCallback(
    (id: string) => {
      if (!workflow) return;
      const idx = workflow.flow.findIndex(s => s.stepId === id);
      if (idx !== -1) setCurrentStepIndex(idx);
    },
    [workflow]
  );

  const nextStep = useCallback(() => {
    if (!workflow) return;
    const step = workflow.flow[currentStepIndex];
    const nextId = step?.defaultNextStep;
    if (nextId) goToStep(nextId);
    else if (currentStepIndex < workflow.flow.length - 1)
      setCurrentStepIndex(i => i + 1);
  }, [workflow, currentStepIndex, goToStep]);

  const currentStep = workflow?.flow[currentStepIndex] || null;

  const executeGenerator = useCallback(
    async (generatorKey: string, node: any, workflowData: any, flowStep: any) => {
      const endpoint = '/api/v1/chatbot/generators/execute';

      const requestBody: any = {
        generatorKey,
        workflow_data: {
          ...workflowData,
          _flow_step: flowStep
        }
      };

      // Handle agent mode params
      if (flowStep.params?.agent_mode) {
        requestBody.agent_mode = true;
        requestBody.json_prompts_reference = flowStep.params.json_prompts_reference || 'agent_prompt';
        
        // Build prompt from node outputs and prompt reference
        if (flowStep.params.prompt) {
          const promptConfig = flowStep.params.prompt;
          if (typeof promptConfig === 'object' && promptConfig.body) {
            let promptBody = promptConfig.body;
            const promptRef = promptConfig.json_prompts_reference;
            
            // Replace placeholders with actual values from node outputs
            if (workflowData.node_outputs?.music_input) {
              const musicDesc = workflowData.node_outputs.music_input.output?.description || 
                               workflowData.node_outputs.music_input.output?.prompt || '';
              promptBody = promptBody.replace('{music_description}', musicDesc);
            }
            
            requestBody.prompt = {
              body: promptBody,
              json_prompts_reference: promptRef,
              agent_mode: true
            };
          } else {
            requestBody.prompt = promptConfig;
          }
        }
      }
      
      // Add other flowStep params (excluding agent mode params to avoid duplicates)
      if (flowStep.params) {
        for (const [key, value] of Object.entries(flowStep.params)) {
          if (key !== 'agent_mode' && key !== 'json_prompts_reference' && key !== 'prompt') {
            requestBody[key] = value;
          }
        }
      }

      const token = localStorage.getItem('access_token');
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token && { 'Authorization': `Bearer ${token}` })
        },
        body: JSON.stringify(requestBody)
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Generator execution failed: ${response.statusText} - ${errorText}`);
      }

      return await response.json();
    },
    []
  );

  const checkRequirements = useCallback(
    (processorState: ActiveProcessorState, flowStep: any): boolean => {
      const requires = (flowStep as any).requires;
      if (!requires || requires.length === 0) {
        return true;
      }

      for (const requiredStepId of requires) {
        if (!processorState.processedSteps.has(requiredStepId)) {
          const requiredStep = processorState.processor.flow.find(s => s.stepId === requiredStepId);
          if (requiredStep && requiredStep.nodeKey) {
            const hasOutput = processorState.nodeOutputs?.has(requiredStep.nodeKey);
            if (!hasOutput) {
              return false;
            }
          } else if (!processorState.processedSteps.has(requiredStepId)) {
            return false;
          }
        }
      }
      return true;
    },
    []
  );

  const processProcessorFlowStep = useCallback(
    async (processorState: ActiveProcessorState, stepIndex: number) => {
      const flowStep = processorState.processor.flow[stepIndex];
      if (!flowStep) {
        console.warn(`Processor step at index ${stepIndex} not found`);
        return;
      }
      
      if (processorState.processedSteps.has(flowStep.stepId)) {
        console.log(`Processor step ${flowStep.stepId} already processed, skipping`);
        return;
      }

      if (!checkRequirements(processorState, flowStep)) {
        const requires = (flowStep as any).requires;
        console.log(`Step ${flowStep.stepId} waiting for requirements:`, requires);
        return;
      }

      console.log(`Processing processor step ${flowStep.stepId} (${flowStep.type})`);
      processorState.processedSteps.add(flowStep.stepId);
      processorState.currentStepIndex = stepIndex;
      activeProcessor.current = processorState;

      if (flowStep.type === 'text' && flowStep.content) {
        context.addAssistantMessageWithDelay({ role: 'assistant', content: flowStep.content }, 300);

        const advanceMode = flowStep.advance || 'auto';
        if (advanceMode === 'auto') {
          const nextId = flowStep.nextStep || flowStep.defaultNextStep;
          if (nextId === 'complete') {
            activeProcessor.current = null;
            setTimeout(nextStep, 600);
            return;
          } else if (nextId) {
            const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
            if (nextIndex !== -1) {
              setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 600);
              return;
            }
          }
        }
        return;
      }

      if (flowStep.type === 'node' && flowStep.nodeKey) {
        const node = await fetchData(`/api/v1/chatbot/nodes/${flowStep.nodeKey}`);
        if (!node) return;

        if (node.type === 'string' && node.category === 'string') {
          const previousTextStep = processorState.processor.flow
            .slice(0, stepIndex)
            .find(s => s.nodeKey && processorState.nodeOutputs?.has(s.nodeKey));
          
          if (previousTextStep && processorState.nodeOutputs?.has(previousTextStep.nodeKey || '')) {
            const textOutput = processorState.nodeOutputs.get(previousTextStep.nodeKey || '');
            const textContent = textOutput?.output?.text || textOutput?.output?.generated_text || '';
            if (textContent) {
              context.setMessages(prev => [...prev, {
                id: `assistant-${Date.now()}`,
                role: 'assistant',
                content: textContent,
                timestamp: new Date()
              }]);
            }
          }

          const nextId = flowStep.defaultNextStep || flowStep.nextStep;
          if (nextId === 'complete') {
            activeProcessor.current = null;
            setTimeout(nextStep, 1000);
          } else if (nextId) {
            const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
            if (nextIndex !== -1) {
              setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
            }
          }
          return;
        }

        if (node.category === 'audio' && node.type !== 'generator' && node.type !== 'input') {
          const previousAudioStep = processorState.processor.flow
            .slice(0, stepIndex)
            .find(s => {
              const prevNode = processorState.nodeOutputs?.get(s.nodeKey || '');
              return prevNode && (prevNode.output?.file || prevNode.output?.s3_url || prevNode.output?.audio);
            });
          
          if (previousAudioStep && processorState.nodeOutputs?.has(previousAudioStep.nodeKey || '')) {
            const audioOutput = processorState.nodeOutputs.get(previousAudioStep.nodeKey || '');
            const audioUrl = audioOutput?.output?.file || audioOutput?.output?.s3_url;
            if (audioUrl) {
              context.setMessages(prev => [...prev, {
                id: `assistant-${Date.now()}`,
                role: 'assistant',
                content: 'Audio file is ready',
                timestamp: new Date(),
                files: {
                  audio: [audioUrl],
                  images: []
                }
              }]);
            }
          }

          const nextId = flowStep.defaultNextStep || flowStep.nextStep;
          if (nextId === 'complete') {
            activeProcessor.current = null;
            setTimeout(nextStep, 1000);
          } else if (nextId) {
            const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
            if (nextIndex !== -1) {
              setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
            }
          }
          return;
        }

        if (node.type === 'generator' && flowStep.advance === 'auto') {
          const workflowData: any = {
            node_outputs: {}
          };

          if (processorState.nodeOutputs) {
            for (const [nodeKey, output] of processorState.nodeOutputs.entries()) {
              workflowData.node_outputs[nodeKey] = output;
            }
            console.log('Building workflowData with nodeOutputs:', Object.keys(workflowData.node_outputs));
          } else {
            console.warn('No nodeOutputs found in processorState');
          }

          const previousSteps = processorState.processor.flow.slice(0, stepIndex);
          for (const prevStep of previousSteps) {
            if (prevStep.type === 'node' && prevStep.nodeKey) {
              if (!workflowData.node_outputs[prevStep.nodeKey]) {
                // Try to get from stored nodeOutputs first
                if (processorState.nodeOutputs?.has(prevStep.nodeKey)) {
                  workflowData.node_outputs[prevStep.nodeKey] = processorState.nodeOutputs.get(prevStep.nodeKey);
                } else if (prevStep.nodeKey === 'music_input' || prevStep.nodeKey === 'image_input') {
                  // Fallback to user messages
                  const allUserMessages = context.messages.filter((m: any) => m.role === 'user');
                  const lastUserMessage = allUserMessages[allUserMessages.length - 1];
                  if (lastUserMessage) {
                    workflowData.node_outputs[prevStep.nodeKey] = {
                      output: {
                        prompt: lastUserMessage.content || '',
                        description: lastUserMessage.content || '',
                        file: lastUserMessage.files?.audio?.[0] || lastUserMessage.files?.images?.[0]
                      }
                    };
                  }
                } else if (prevStep.nodeKey === 'text_generation') {
                  // Get output from previous text generation
                  if (processorState.nodeOutputs?.has(prevStep.stepId || prevStep.nodeKey)) {
                    workflowData.node_outputs[prevStep.stepId || prevStep.nodeKey] = processorState.nodeOutputs.get(prevStep.stepId || prevStep.nodeKey);
                  }
                }
              }
            }
          }

          console.log('Executing generator:', flowStep.nodeKey, 'with workflowData:', JSON.stringify(workflowData, null, 2));
          
          try {
            if ((window as any).activeProcessorState) {
              (window as any).activeProcessorState = activeProcessor.current;
            }
            
            const result = await executeGenerator(flowStep.nodeKey, node, workflowData, flowStep);
            console.log('Generator execution result:', result);

            if (!result.success) {
              console.error('Generator execution failed:', result);
              context.setMessages(prev => [...prev, {
                id: `error-${Date.now()}`,
                role: 'assistant',
                content: `Error: ${result.error || 'Generator execution failed'}`,
                timestamp: new Date()
              }]);
              
              const nextId = flowStep.defaultNextStep || flowStep.nextStep;
              if (nextId === 'complete') {
                activeProcessor.current = null;
                setTimeout(nextStep, 1000);
              } else if (nextId) {
                const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
                if (nextIndex !== -1) {
                  setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
                }
              }
              return;
            }

            if (result.agent_mode && result.conversation) {
              result.conversation.forEach((conv: any, idx: number) => {
                context.setMessages(prev => [...prev, {
                  id: `agent-input-${Date.now()}-${idx}`,
                  role: 'assistant',
                  content: `**Agent Input (Iteration ${conv.iteration}):**\n\n${conv.input}`,
                  timestamp: new Date()
                }]);
                
                context.setMessages(prev => [...prev, {
                  id: `agent-raw-${Date.now()}-${idx}`,
                  role: 'assistant',
                  content: `**Raw Output:**\n\n${conv.raw_output}`,
                  timestamp: new Date()
                }]);
                
                if (conv.parsed_output) {
                  const outputText = conv.parsed_output.output || '';
                  const isValidated = conv.parsed_output.validation || false;
                  context.setMessages(prev => [...prev, {
                    id: `agent-parsed-${Date.now()}-${idx}`,
                    role: 'assistant',
                    content: `**Generated Output ${isValidated ? '(✅ Validated)' : '(⏳ Pending)'}:**\n\n${outputText}`,
                    timestamp: new Date(),
                    agent: {
                      validation: isValidated,
                      output: outputText,
                      parsed: conv.parsed_output
                    }
                  }]);
                }
              });
              
              if (result.waiting_feedback && result.agent_session_id) {
                context.setMessages(prev => [...prev, {
                  id: `agent-feedback-request-${Date.now()}`,
                  role: 'assistant',
                  content: `Please review the generated output above. Provide your feedback below, or type "yes" to approve and continue.`,
                  timestamp: new Date(),
                  agentFeedback: {
                    waiting: true,
                    sessionId: result.agent_session_id,
                    generatorKey: result.generator_key || 'text_generation',
                    flowStep: flowStep,
                    metadata: {
                      description: flowStep.params?.description,
                      genre: flowStep.params?.genre,
                      aiPromptType: flowStep.params?.aiPromptType,
                      json_prompts_reference: flowStep.params?.json_prompts_reference
                    }
                  }
                }]);
                
                return;
              }
              
              if (result.final_output && result.validated) {
                const outputs: any = { text: result.final_output, generated_text: result.final_output };
                if (processorState.nodeOutputs) {
                  processorState.nodeOutputs.set(flowStep.nodeKey, { output: outputs });
                  processorState.nodeOutputs.set(flowStep.stepId, { output: outputs });
                  console.log('Stored agent mode final output for', flowStep.stepId, ':', outputs);
                }
              } else if (result.conversation && result.conversation.length > 0) {
                const lastConv = result.conversation[result.conversation.length - 1];
                if (lastConv.parsed_output && lastConv.parsed_output.output) {
                  const outputs: any = { 
                    text: lastConv.parsed_output.output, 
                    generated_text: lastConv.parsed_output.output 
                  };
                  if (processorState.nodeOutputs) {
                    processorState.nodeOutputs.set(flowStep.nodeKey, { output: outputs });
                    processorState.nodeOutputs.set(flowStep.stepId, { output: outputs });
                    console.log('Stored agent mode output (not validated) for', flowStep.stepId, ':', outputs);
                  }
                }
              }
            } else if (result.result || result.generated_text || result.s3_url || result.request_id) {
              if (result.request_id && (node.category === 'llm' || node.category === 'string')) {
                const requestId = result.request_id;
                console.log('Text generation started with request_id:', requestId, 'Waiting for streaming to complete...');
                
                if (typeof window !== 'undefined' && flowStep.nodeKey) {
                  if ((window as any).taskIdToNodeKeyMap) {
                    (window as any).taskIdToNodeKeyMap.set(requestId, flowStep.nodeKey);
                  } else {
                    (window as any).taskIdToNodeKeyMap = new Map([[requestId, flowStep.nodeKey]]);
                  }
                }
                
                const waitForCompletion = (maxWait: number = 60000) => {
                  return new Promise<void>((resolve) => {
                    const startTime = Date.now();
                    const checkInterval = setInterval(() => {
                      if (!flowStep.nodeKey) {
                        clearInterval(checkInterval);
                        resolve();
                        return;
                      }
                      
                      const storedOutput = processorState.nodeOutputs?.get(flowStep.nodeKey);
                      const hasRealText = storedOutput?.output?.text && 
                                         !storedOutput.output.text.startsWith('[Request ID:');
                      
                      if (hasRealText) {
                        clearInterval(checkInterval);
                        console.log('Streaming completed, found text in nodeOutputs:', storedOutput.output.text.substring(0, 50));
                        resolve();
                      } else if (Date.now() - startTime > maxWait) {
                        clearInterval(checkInterval);
                        console.warn('Timeout waiting for streaming completion for', requestId);
                        resolve();
                      }
                    }, 500);
                    
                    setTimeout(() => {
                      clearInterval(checkInterval);
                      resolve();
                    }, maxWait);
                  });
                };
                
                await waitForCompletion();
                
                const finalOutput = processorState.nodeOutputs?.get(flowStep.nodeKey);
                if (finalOutput?.output?.text && !finalOutput.output.text.startsWith('[Request ID:')) {
                  console.log('Successfully stored streaming result for', flowStep.nodeKey);
                } else {
                  console.warn('Streaming did not complete in time for', requestId);
                  if (processorState.nodeOutputs) {
                    processorState.nodeOutputs.set(flowStep.nodeKey, { 
                      output: { 
                        text: `[Request ID: ${requestId}]`,
                        generated_text: `[Request ID: ${requestId}]`
                      } 
                    });
                  }
                }
              } else {
                const generatedContent = result.result?.generated_text || result.result?.text || result.generated_text || '';
                const audioUrl = result.result?.s3_url || result.result?.file || result.s3_url;
                
                if (generatedContent) {
                  context.setMessages(prev => [...prev, {
                    id: `assistant-${Date.now()}`,
                    role: 'assistant',
                    content: generatedContent,
                    timestamp: new Date()
                  }]);
                }

                if (audioUrl && node.category === 'audio') {
                  context.setMessages(prev => [...prev, {
                    id: `assistant-audio-${Date.now()}`,
                    role: 'assistant',
                    content: 'Generated audio is ready',
                    timestamp: new Date(),
                    files: { 
                      audio: [audioUrl],
                      images: []
                    }
                  }]);
                }

                if (processorState.nodeOutputs) {
                  const outputs: any = result.result || result.outputs || {};
                  if (result.generated_text) outputs.generated_text = result.generated_text;
                  if (result.text) outputs.text = result.text;
                  if (result.s3_url) outputs.s3_url = result.s3_url;
                  if (audioUrl) outputs.s3_url = audioUrl;
                  if (Object.keys(outputs).length > 0) {
                    processorState.nodeOutputs.set(flowStep.nodeKey, { output: outputs });
                    console.log('Stored generator output for', flowStep.nodeKey, ':', outputs);
                  }
                }
              }
            } else {
              console.warn('Generator returned no result data:', result);
            }
            
            const nextId = flowStep.defaultNextStep || flowStep.nextStep;
            if (nextId === 'complete') {
              activeProcessor.current = null;
              setTimeout(nextStep, 1000);
            } else if (nextId) {
              const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
              if (nextIndex !== -1) {
                setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
              }
            }
          } catch (error: any) {
            console.error(`Error executing generator ${flowStep.nodeKey}:`, error);
            context.setMessages(prev => [...prev, {
              id: `error-${Date.now()}`,
              role: 'assistant',
              content: `Error executing generator: ${error.message || 'Unknown error'}`,
              timestamp: new Date()
            }]);
            
            const nextId = flowStep.defaultNextStep || flowStep.nextStep;
            if (nextId === 'complete') {
              activeProcessor.current = null;
              setTimeout(nextStep, 1000);
            } else if (nextId) {
              const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
              if (nextIndex !== -1) {
                setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
              }
            }
          }
          return;
        }

        const mergedNodeData = {
          ...node,
          prompt_input: flowStep.params?.enablePromptInput !== undefined 
            ? flowStep.params.enablePromptInput 
            : (node.prompt_input !== undefined ? node.prompt_input : false),
          file_input: flowStep.params?.enableFileInput !== undefined 
            ? flowStep.params.enableFileInput 
            : (node.file_input !== undefined ? node.file_input : false),
          parameters: {
            ...node.parameters,
            ...(flowStep.params?.maxFiles !== undefined && { maxFiles: flowStep.params.maxFiles }),
            ...(flowStep.params?.placeholder !== undefined && { placeholder: flowStep.params.placeholder })
          }
        };

        processorState.currentNodeData = mergedNodeData;
        setProcessorNodeUpdate(prev => prev + 1);

        if (node.type === 'input') {
          const placeholder = flowStep.params?.placeholder || mergedNodeData.parameters?.placeholder || node.name || 'Please provide your input';
          let promptMessage = placeholder;
          
          if (mergedNodeData.file_input && mergedNodeData.prompt_input) {
            promptMessage = placeholder || `Please provide your ${node.category || 'input'} or upload files`;
          } else if (mergedNodeData.file_input) {
            promptMessage = placeholder || `Please upload your ${node.category || 'files'}`;
          } else if (mergedNodeData.prompt_input) {
            promptMessage = placeholder || `Please describe what you'd like to ${node.category || 'create'}`;
          }
          
          const lastMessage = context.messages[context.messages.length - 1];
          if (!lastMessage || lastMessage.content !== promptMessage || lastMessage.role !== 'assistant') {
            context.addAssistantMessageWithDelay({ 
              role: 'assistant', 
              content: promptMessage,
              enableFileInput: mergedNodeData.file_input,
              enablePromptInput: mergedNodeData.prompt_input
            }, 300);
          }
        }

        if (mergedNodeData.file_input) {
          context.setFileInputEnabled(true);
        }
        if (mergedNodeData.prompt_input) {
          context.setInputEnabled(true);
        }

        if (flowStep.advance === 'auto') {
          const nextId = flowStep.defaultNextStep || flowStep.nextStep;
          if (nextId === 'complete') {
            activeProcessor.current = null;
            setTimeout(nextStep, 1500);
          } else if (nextId) {
            const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
            if (nextIndex !== -1) {
              setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1500);
            }
          }
        }
        return;
      }

      if (flowStep.type === 'util' && (flowStep.advance === 'auto' || flowStep.background)) {
        const nextId = flowStep.defaultNextStep || flowStep.nextStep;
        if (nextId === 'complete') {
          activeProcessor.current = null;
          setTimeout(nextStep, 1000);
        } else if (nextId) {
          const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === nextId);
          if (nextIndex !== -1) {
            setTimeout(() => processProcessorFlowStep(processorState, nextIndex), 1000);
          }
        }
      }
    },
    [context, nextStep, executeGenerator, checkRequirements]
  );

  const processStep = useCallback(
    async (step: WorkflowStep) => {
      if (processedSteps.current.has(step.stepId)) {
        return;
      }
      processedSteps.current.add(step.stepId);

      if (step.type === 'text' && step.content) {
        context.addAssistantMessageWithDelay({ role: 'assistant', content: step.content }, 300);
        
        const nextId = step.nextStep || step.defaultNextStep;
        if (nextId) {
          setTimeout(() => goToStep(nextId), 600);
        } else {
          setTimeout(() => nextStep(), 600);
        }
        return;
      }

      if (step.type === 'node') {
        const node = await fetchData(`/api/v1/chatbot/nodes/${step.nodeKey}`);
        if (!node) return;

        if (node.file_input !== undefined) {
          context.setFileInputEnabled(node.file_input);
        }
        if (node.prompt_input !== undefined) {
          context.setInputEnabled(node.prompt_input);
        }

        const isOptional = node.validation?.required === false || node.parameters?.required === false;
        if (isOptional) setTimeout(nextStep, 1500);
        return;
      }

      if (step.type === 'processor') {
        console.log('Loading processor:', step.processorKey);
        const processor = await fetchData(`/api/v1/chatbot/processors/${step.processorKey}`);
        if (!processor?.flow?.length) {
          console.warn('Processor has no flow or failed to load:', step.processorKey);
          context.addAssistantMessageWithDelay(
            { role: 'assistant', content: processor?.description || 'Processing...' },
            300
          );
          setTimeout(nextStep, 1000);
          return;
        }

        console.log('Processor loaded, starting flow:', processor.id, 'with', processor.flow.length, 'steps');
        const processorState: ActiveProcessorState = {
          processor: processor as ProcessorDefinition,
          currentStepIndex: 0,
          processedSteps: new Set(),
          nodeOutputs: new Map()
        };
        
        activeProcessor.current = processorState;
        console.log('Processing first processor step:', processor.flow[0]?.stepId);
        processProcessorFlowStep(processorState, 0).catch(err => {
          console.error('Error starting processor flow:', err);
          activeProcessor.current = null;
          nextStep();
        });
        return;
      }
    },
    [context, nextStep, goToStep, processProcessorFlowStep]
  );

  useEffect(() => {
    if (!currentStep) {
      console.log('No current step to process');
      return;
    }
    console.log('Processing workflow step:', currentStep.stepId, currentStep.type, currentStep.processorKey || currentStep.nodeKey);
    processStep(currentStep);
  }, [currentStep, processStep]);

  const handleUserInput = useCallback(
    async (input: string, skipMessageCreation: boolean = false) => {
      if (!input.trim() && !skipMessageCreation) return;
      
      if (!skipMessageCreation) {
        const now = Date.now();
        context.setMessages(prev => [...prev, {
          id: `user-${now}`,
          role: 'user',
          content: input,
          timestamp: new Date()
        }]);
      }

      if (activeProcessor.current) {
        const processorState = activeProcessor.current;
        const currentFlowStep = processorState.processor.flow[processorState.currentStepIndex];
        
        if (currentFlowStep?.type === 'node' && currentFlowStep.transitions) {
          const hasUploadedFiles = (context.uploadedAudio.length > 0 || context.uploadedImages.length > 0);
          const lastMessage = context.messages[context.messages.length - 1];
          const hasMessageFiles = lastMessage?.files && (
            lastMessage.files.audio?.length > 0 || 
            lastMessage.files.images?.length > 0
          );
          const hasUserFiles = hasUploadedFiles || hasMessageFiles;
          const hasUserPrompt = input.trim().length > 0;

          let transitionMatched = false;

          for (const transition of currentFlowStep.transitions) {
            const condition = transition.condition;
            if (!condition) continue;

            let conditionMet = false;
            
            if (condition.type === 'hasFiles') {
              conditionMet = hasUserFiles === condition.value;
            } else if (condition.type === 'hasPromptOnly') {
              conditionMet = (hasUserPrompt && !hasUserFiles) === condition.value;
            } else if (condition.type === 'hasPromptAndFile') {
              conditionMet = (hasUserPrompt && hasUserFiles) === condition.value;
            } else if (condition.type === 'hasPrompt') {
              conditionMet = hasUserPrompt === condition.value;
            } else if (condition.type === 'hasImages') {
              conditionMet = (context.uploadedImages.length > 0 || (lastMessage?.files?.images?.length ?? 0) > 0) === condition.value;
            }

            if (conditionMet && transition.nextStep) {
              transitionMatched = true;
              
              // Store output for the current input node
              if (currentFlowStep.nodeKey === 'music_input' || currentFlowStep.nodeKey === 'image_input') {
                const output: any = {
                  output: {
                    prompt: input.trim() || '',
                    description: input.trim() || ''
                  }
                };
                
                if (hasUserFiles && lastMessage?.files) {
                  if (lastMessage.files.audio && lastMessage.files.audio.length > 0) {
                    output.output.file = lastMessage.files.audio[0];
                  } else if (lastMessage.files.images && lastMessage.files.images.length > 0) {
                    output.output.file = lastMessage.files.images[0];
                  }
                }
                
                if (!processorState.nodeOutputs) {
                  processorState.nodeOutputs = new Map();
                }
                processorState.nodeOutputs.set(currentFlowStep.nodeKey || '', output);
                console.log('Transition: Stored output for', currentFlowStep.nodeKey, ':', JSON.stringify(output, null, 2));
              }

              const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === transition.nextStep);
              if (nextIndex !== -1) {
                setTimeout(() => {
                  processProcessorFlowStep(processorState, nextIndex).catch(err => {
                    console.error('Error processing processor transition step:', err);
                    activeProcessor.current = null;
                    nextStep();
                  });
                }, 300);
                return;
              }
            }
          }

          if (!transitionMatched) {
            const defaultNextId = currentFlowStep.defaultNextStep || currentFlowStep.nextStep;
            if (defaultNextId === 'complete') {
              activeProcessor.current = null;
              setTimeout(nextStep, 300);
            } else if (defaultNextId) {
              if (currentFlowStep.nodeKey === 'music_input' || currentFlowStep.nodeKey === 'image_input') {
                const output: any = {
                  output: {
                    prompt: input.trim() || '',
                    description: input.trim() || ''
                  }
                };
                
                if (hasUserFiles && lastMessage?.files) {
                  if (lastMessage.files.audio && lastMessage.files.audio.length > 0) {
                    output.output.file = lastMessage.files.audio[0];
                  } else if (lastMessage.files.images && lastMessage.files.images.length > 0) {
                    output.output.file = lastMessage.files.images[0];
                  }
                }
                
                if (!processorState.nodeOutputs) {
                  processorState.nodeOutputs = new Map();
                }
                processorState.nodeOutputs.set(currentFlowStep.nodeKey || '', output);
              }

              const nextIndex = processorState.processor.flow.findIndex(s => s.stepId === defaultNextId);
              if (nextIndex !== -1) {
                setTimeout(() => {
                  processProcessorFlowStep(processorState, nextIndex).catch(err => {
                    console.error('Error processing processor default step:', err);
                    activeProcessor.current = null;
                    nextStep();
                  });
                }, 300);
                return;
              }
            } else {
              activeProcessor.current = null;
              nextStep();
            }
          }
          return;
        }
      }

      nextStep();
    },
    [context, nextStep, processProcessorFlowStep]
  );

  const handleFileUpload = useCallback(
    async (files: File[]) => {
      if (!files.length) return;
    },
    []
  );

  const handleAIGeneration = useCallback(async () => {
    context.addAssistantMessageWithDelay({ role: 'assistant', content: 'Generating with AI...' }, 300);
    setTimeout(nextStep, 1500);
  }, [context, nextStep]);

  const handleAgentFeedback = useCallback(
    async (feedback: string, sessionId: string, generatorKey: string, metadata: any, flowStep: any) => {
      if (!feedback.trim()) return;
      
      context.setMessages(prev => [...prev, {
        id: `user-feedback-${Date.now()}`,
        role: 'user',
        content: feedback,
        timestamp: new Date()
      }]);
      
      try {
        const token = localStorage.getItem('accessToken');
        if (!token) {
          throw new Error('No authentication token');
        }
        
        const response = await fetch('/api/chatbot/generators/agent-feedback', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            agent_session_id: sessionId,
            user_feedback: feedback,
            generator_key: generatorKey,
            ...metadata
          })
        });
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        
        const result = await response.json();
        
        if (result.agent_mode && result.conversation) {
          result.conversation.forEach((conv: any, idx: number) => {
            context.setMessages(prev => [...prev, {
              id: `agent-input-fb-${Date.now()}-${idx}`,
              role: 'assistant',
              content: `**Agent Input (Iteration ${conv.iteration}):**\n\n${conv.input}`,
              timestamp: new Date()
            }]);
            
            context.setMessages(prev => [...prev, {
              id: `agent-raw-fb-${Date.now()}-${idx}`,
              role: 'assistant',
              content: `**Raw Output:**\n\n${conv.raw_output}`,
              timestamp: new Date()
            }]);
            
            if (conv.parsed_output) {
              const outputText = conv.parsed_output.output || '';
              const isValidated = conv.parsed_output.validation || false;
              context.setMessages(prev => [...prev, {
                id: `agent-parsed-fb-${Date.now()}-${idx}`,
                role: 'assistant',
                content: `**Generated Output ${isValidated ? '(✅ Validated)' : '(⏳ Pending)'}:**\n\n${outputText}`,
                timestamp: new Date(),
                agent: {
                  validation: isValidated,
                  output: outputText,
                  parsed: conv.parsed_output
                }
              }]);
            }
          });
          
          if (result.waiting_feedback && result.agent_session_id) {
            context.setMessages(prev => [...prev, {
              id: `agent-feedback-request-${Date.now()}`,
              role: 'assistant',
              content: `Please review the generated output above. Provide your feedback below, or type "yes" to approve and continue.`,
              timestamp: new Date(),
              agentFeedback: {
                waiting: true,
                sessionId: result.agent_session_id,
                generatorKey: result.generator_key || generatorKey,
                flowStep: flowStep,
                metadata: metadata
              }
            }]);
          } else if (result.validated && result.final_output) {
            if (activeProcessor.current && flowStep) {
              const processorState = activeProcessor.current;
              const outputs: any = { 
                text: result.final_output, 
                generated_text: result.final_output 
              };
              
              if (processorState.nodeOutputs) {
                processorState.nodeOutputs.set(flowStep.nodeKey, { output: outputs });
                processorState.nodeOutputs.set(flowStep.stepId, { output: outputs });
                console.log('Stored validated agent output for', flowStep.stepId, ':', outputs);
              }
              
              const currentStepIndex = processorState.currentStepIndex;
              const nextStepId = flowStep.nextStep;
              
              if (nextStepId === 'complete') {
                activeProcessor.current = null;
                setTimeout(nextStep, 300);
              } else if (nextStepId) {
                const nextIndex = processorState.processor.flow.findIndex((s: any) => s.stepId === nextStepId);
                if (nextIndex !== -1) {
                  setTimeout(() => {
                    processProcessorFlowStep(processorState, nextIndex).catch((err: any) => {
                      console.error('Error processing next step after agent validation:', err);
                      activeProcessor.current = null;
                      nextStep();
                    });
                  }, 300);
                }
              }
            }
          }
        }
      } catch (error: any) {
        console.error('Error submitting agent feedback:', error);
        context.setMessages(prev => [...prev, {
          id: `error-${Date.now()}`,
          role: 'assistant',
          content: `Error submitting feedback: ${error.message}`,
          timestamp: new Date()
        }]);
      }
    },
    [context, nextStep, processProcessorFlowStep]
  );

  return {
    workflow,
    currentStep,
    currentStepIndex,
    isLoading: loading,
    error,
    nextStep,
    goToStep,
    processStep,
    handleUserInput,
    handleFileUpload,
    handleAIGeneration,
    handleAgentFeedback,
    activeProcessorRef: activeProcessor,
    processorNodeUpdate
  };
}
