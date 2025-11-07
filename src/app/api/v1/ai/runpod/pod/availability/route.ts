import { NextRequest, NextResponse } from 'next/server';
import { withErrorHandling } from '../../../../middleware/error-handling';
import { makeBackendRequest } from '../../../../lib/utils/backend';

export const GET = withErrorHandling(async (request: NextRequest) => {
  const searchParams = request.nextUrl.searchParams;
  const workflowId = searchParams.get('workflow_id');
  
  const url = workflowId 
    ? `/api/ai/runpod/pod/availability?workflow_id=${encodeURIComponent(workflowId)}`
    : '/api/ai/runpod/pod/availability';
  
  const response = await makeBackendRequest(url, {
    method: 'GET',
    timeout: 35000,
  });

  const data = await response.json();
  return NextResponse.json(data, { status: response.status });
});

