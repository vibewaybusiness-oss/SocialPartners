# Clipizy

AI chatbot platform for longform content creation, generating music clips, videos, and social media content with intelligent audio analysis and visual synchronization.

## Overview

Clipizy is an advanced AI chatbot designed for longform content creation across multiple media types. The platform combines conversational AI with sophisticated workflow orchestration to guide users through the creation of music videos, video clips, business advertisements, and automated workflows. Through an interactive chat interface, users can generate, refine, and produce high-quality multimedia content with AI-powered assistance for audio analysis, visual generation, music composition, and video production.

## Features

- **AI Chatbot Interface**: Interactive conversational AI that guides users through longform content creation workflows with iterative refinement and validation
- **Longform Content Creation**: Create complete music videos, video clips, business advertisements, and automated workflows through structured AI workflows
- **Agent Mode Generation**: Iterative AI agent system that refines content based on user feedback, ensuring high-quality outputs through validation loops
- **AI-Powered Content Generation**: Advanced AI algorithms create stunning music and videos, social media content, and long-form media from audio in minutes
- **Workflow Orchestration**: Node-based workflow system with processors, generators, and utilities for complex multi-step content creation
- **Multiple Visual Styles & Themes**: Choose from various visual styles including abstract, cinematic, animated, and more
- **Smart Audio Analysis & Sync**: Intelligent audio analysis automatically syncs visuals with music
- **4K High Quality Output**: Export videos in up to 4K resolution with professional-grade quality
- **Lightning Fast Processing**: Optimized AI processing for rapid content generation
- **Real-time Progress Tracking**: Monitor AI workflow execution and generation progress via WebSocket connections
- **Unified Project Management**: Support for multiple project types (music-clip, video-edit, audio-edit, image-edit, custom)
- **Analytics & Insights**: Track content performance and get insights on what's working

## Tech Stack

### Frontend
- **Next.js 14** - React framework with App Router
- **React 18** - UI library
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **shadcn/ui** - UI component library
- **Framer Motion** - Animations
- **Zod** - Schema validation
- **React Hook Form** - Form management

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - ORM and database management
- **PostgreSQL** - Primary database
- **Pydantic** - Data validation
- **Alembic** - Database migrations
- **Uvicorn** - ASGI server

### AI/ML Services
- **ComfyUI** - AI workflow execution
- **RunPod** - Cloud GPU infrastructure
- **ProducerAI** - Music generation services
- **Custom Audio Analyzer** - Audio processing and analysis

### Infrastructure
- **Amazon S3** - File storage
- **Redis** (optional) - Caching
- **Stripe** - Payment processing

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   AI Services   │
│   Next.js 14    │◄──►│   FastAPI       │◄──►│   ComfyUI       │
│   React 18      │    │   SQLAlchemy    │    │   RunPod        │
│   TypeScript    │    │   PostgreSQL    │    │   ProducerAI    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Frontend Structure

```
src/
├── app/                    # Next.js App Router
│   ├── dashboard/         # Protected user dashboard
│   ├── create/            # Content creation workflows
│   ├── projects/          # Project management
│   └── auth/             # Authentication
├── components/            # React components
│   ├── ui/               # shadcn/ui base components
│   ├── forms/            # Form components
│   └── layout/           # Layout components
├── hooks/                # Custom React hooks
│   ├── ai/               # AI integration hooks
│   ├── storage/          # Data persistence hooks
│   └── business/         # Business logic hooks
├── contexts/             # React Context providers
├── lib/                  # API clients and utilities
└── types/                # TypeScript definitions
```

### Backend Structure

```
api/
├── config/               # Configuration management
├── data/                 # Database and storage
├── middleware/           # Request processing
├── models/               # SQLAlchemy models
├── routers/              # API endpoints
├── services/             # Business logic
│   ├── ai/              # AI service workers
│   └── chatbot/        # Chatbot workflow services
├── schemas/              # Pydantic validation
└── workflows/           # Process orchestration
```

## AI & ML Services

### AI Services (`api/services/ai/`)

The AI services module provides unified workers for various AI generation and analysis tasks, all integrated with RunPod queue management.

#### Core Services

**Audio Analyzer Service** (`audio_analyzer_service.py`)
- Analyzes audio files for music clips and projects
- Supports DSP segmentation and LLM-based analysis
- Enqueues analysis tasks to RunPod workers
- Returns request IDs for tracking progress
- Key methods:
  - `enqueue()` - Queue audio analysis jobs
  - Parameters: `project_id`, `s3_url`, `analyzer`, `llm_analyzer`, `chat_id`

**Text Generator Service** (`text_generator_service.py`)
- Generates text content using LLM models (default: mistral:7b)
- Supports JSON output mode for structured responses
- Includes JSON parsing utilities for extracting structured data from LLM outputs
- Removes thinking/reasoning tags from responses
- Key methods:
  - `generate_text()` - Generate text with optional JSON output
  - Parameters: `prompt`, `model`, `chat_id`, `json_output`

**Image Generator Service** (`image_generator_service.py`)
- Generates images from text prompts using Qwen models
- Supports image editing with reference images
- Configurable dimensions, steps, and guidance
- Key methods:
  - `generate_image()` - Generate or edit images
  - Parameters: `prompt`, `reference_image_s3`, `width`, `height`, `steps`, `guidance`, `model`

**Image Analyzer Service** (`image_analyzer_service.py`)
- Describes and analyzes images using vision-language models
- Uses Qwen3-VL for image understanding
- Key methods:
  - `describe_image()` - Analyze and describe image content
  - Parameters: `prompt`, `image_s3_url`, `model`, `chat_id`

**Video Generator Service** (`video_generator_service.py`)
- Generates videos from prompts and reference materials
- Supports image and audio references
- Configurable duration, resolution, and frame rate
- Uses WAN video generation workflow
- Key methods:
  - `generate_video()` - Generate videos
  - Parameters: `prompt`, `reference_image_s3`, `reference_audio`, `duration_seconds`, `width`, `height`, `fps`

**Music Generator Service** (`music_generator_service.py`)
- Generates music tracks from text descriptions
- Uses MMAudio workflow for music generation
- Key methods:
  - `generate_music()` - Generate music tracks
  - Parameters: `prompt`, `model`, `s3_url`, `chat_id`

#### Task Event Hub (`task_event_hub.py`)

Centralized event management system for tracking AI task progress:

- **Real-time Updates**: WebSocket-based notifications for task status
- **Multi-subscription**: Support for task-specific and chat-specific subscriptions
- **Event Broadcasting**: Emits task updates with status, duration, URLs, and errors
- **Key Features**:
  - Subscribe to task updates via callbacks or WebSockets
  - Chat-based event grouping for workflow tracking
  - Automatic cleanup of disconnected WebSocket connections
  - Thread-safe subscription management

Usage:
```python
from api.services.ai.task_event_hub import get_task_event_hub

hub = get_task_event_hub()
await hub.emit_task_update(
    task_id="task-123",
    chat_id="chat-456",
    status="completed",
    duration=45.2,
    url="s3://bucket/file.mp4"
)
```

#### RunPod Integration

All AI services integrate with RunPod queue management:
- **Queue-based Execution**: Tasks are queued and executed asynchronously
- **Request Tracking**: Each service returns a request ID for progress monitoring
- **Status Management**: Task status updates flow through the event hub
- **Error Handling**: Comprehensive error reporting and status tracking

### Chatbot Services (`api/services/chatbot/`)

The chatbot services provide workflow orchestration and content generation capabilities for conversational AI interactions.

#### Generator Service (`generator_service.py`)

Unified service for executing any generator node type based on configuration:

**Supported Generator Types**:
- `text_generation` - LLM-based text generation with agent mode support
- `video_generation` - Video creation from prompts
- `image_generation` - Image creation and editing
- `music_generation` - Music track generation
- `image_description` - Image analysis and description
- `audio_analysis` - Audio file analysis

**Agent Mode**:
- Iterative refinement loop for text generation
- Validation-based feedback system
- Conversation history management
- Automatic retry with user feedback integration
- JSON output parsing and validation

**Key Features**:
- Configuration-driven generator execution
- Parameter mapping for different generator types
- Automatic event hub integration for progress tracking
- Comprehensive error handling and status reporting

Usage:
```python
from api.services.chatbot import get_generator_service

generator = get_generator_service()
request_id = await generator.execute(
    generator_key="text_generation",
    chat_id="chat-123",
    prompt="Generate lyrics for a pop song",
    agent_mode=True,
    json_prompts_reference="generate-lyrics"
)
```

#### Workflow Service (`workflow_service.py`)

Manages node-based workflows from JSON configuration files:

**Configuration Files**:
- `nodes.json` - Node definitions
- `displays.json` - Display node definitions
- `generators.json` - Generator node definitions
- `processors.json` - Processor definitions
- `utils.json` - Utility functions
- `*-workflow.json` - Workflow definitions

**Key Capabilities**:
- Load and resolve workflow definitions
- Node, processor, and utility lookup
- Workflow resolution with full node data
- Node processing middleware for data persistence
- File upload integration
- Chat history management

**Node Processing Middleware**:
- Automatic project data persistence
- File upload to S3 storage
- Chat status and history management
- Agent conversation tracking
- Error handling and reporting

Usage:
```python
from api.services.chatbot import get_workflow_service

workflow_service = get_workflow_service()
workflow = workflow_service.get_workflow_with_resolved_nodes("workflow-id")
node = workflow_service.get_node("node-key")
```

#### Chatbot Workflows (`chatbot_workflows.py`)

Pipeline definitions for different project types:

**Supported Project Types**:
- `music_video_clip` - Music video generation pipelines
  - Looped Static
  - Looped Animated
  - Recurring Scenes
- `video_clip` - Standard video generation
- `business_ad` - Business advertisement pipelines
- `automate_workflow` - Automation workflows

Each pipeline includes:
- Required and optional fields
- Pipeline metadata
- Type-specific configurations

Usage:
```python
from api.services.chatbot import get_chatbot_workflows

workflows = get_chatbot_workflows()
pipelines = workflows.get_pipelines_for_project_type("music_video_clip")
```

### Service Integration Flow

```
User Request → Chatbot Router → Generator Service
                                    ↓
                           Execute Generator Node
                                    ↓
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
          AI Service Worker                   Task Event Hub
          (Audio/Text/Image/etc.)              (Status Updates)
                    ↓                               ↓
            RunPod Queue Manager            WebSocket Clients
                    ↓
            RunPod Worker Execution
                    ↓
            Result + Event Emission
```

## Prerequisites

- **Node.js** 18+ and npm
- **Python** 3.11+
- **PostgreSQL** 14+
- **Redis** (optional, for caching)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd clipizy
```

### 2. Install Dependencies

#### Frontend

```bash
npm install
```

#### Backend

```bash
pip install -r requirements.txt
```

For full development dependencies:

```bash
pip install -r full-requirements.txt
```

### 3. Environment Configuration

Copy the environment template and configure:

```bash
cp env.template .env
```

Edit `.env` with your configuration:

```env
# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/clipizy
DB_POOL_SIZE=10

# Security Configuration
SECRET_KEY=your-secret-key-change-in-production
JWT_ALGORITHM=HS256

# Amazon S3 Storage Configuration (Required)
S3_BUCKET=clipizy-dev
S3_REGION=us-east-1
S3_ENDPOINT_URL=https://s3.amazonaws.com
S3_ACCESS_KEY=your-aws-access-key
S3_SECRET_KEY=your-aws-secret-key

# AI Services Configuration
COMFYUI_URL=http://localhost:8188
RUNPOD_API_KEY=your-runpod-key
RUNPOD_POD_ID=your-pod-id
PRODUCER_AI_API_KEY=your-producer-key

# OAuth Configuration (Optional)
OAUTH_GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# Application Configuration
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO
FRONTEND_URL=http://localhost:3000
API_HOST=localhost
API_PORT=8000
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### 4. Database Setup

```bash
# Create database
createdb clipizy

# Run migrations (if using Alembic)
alembic upgrade head
```

### 5. Quick Setup

Use the Makefile for automated setup:

```bash
make install
make setup
```

## Running the Application

### Development Mode

#### Using Makefile

```bash
make dev
```

This starts both frontend and backend servers.

#### Manual Start

**Backend:**

```bash
cd api
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**

```bash
npm run dev
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs

### Production Mode

#### Build Frontend

```bash
npm run build
npm start
```

#### Run Backend

```bash
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

## Development

### Available Scripts

#### Frontend

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run linter
npm run lint:fix     # Fix linting issues
npm run typecheck    # TypeScript type checking
npm test             # Run tests
npm run test:watch   # Run tests in watch mode
npm run test:coverage # Generate coverage report
npm run format       # Format code with Prettier
```

#### Backend

```bash
pytest               # Run tests
pytest --cov=api     # Run tests with coverage
black api/           # Format code
isort api/           # Sort imports
flake8 api/          # Lint code
```

### Makefile Commands

```bash
make help           # Show available commands
make install        # Install all dependencies
make setup          # Initial development setup
make dev            # Start development servers
make test           # Run all tests
make lint           # Run linting
make lint-fix       # Fix linting issues
make format         # Format code
make build          # Build application
make clean          # Clean build artifacts
make coverage       # Generate coverage reports
make security       # Run security checks
```

### Code Standards

- **Frontend**: Follow Next.js and React best practices, use TypeScript, follow ESLint rules
- **Backend**: Follow PEP 8, use type hints, write docstrings, maintain 80%+ test coverage
- **Commits**: Use conventional commit messages
- **Testing**: Write unit and integration tests for new features

### Project Structure Guidelines

1. **Adding New Features**:
   - Define data models in `api/models/`
   - Create validation schemas in `api/schemas/`
   - Implement business logic in `api/services/`
   - Add API endpoints in `api/routers/`
   - Create frontend components in `src/components/`
   - Add hooks for business logic in `src/hooks/`

2. **Database Changes**:
   - Create Alembic migrations for schema changes
   - Update models and schemas
   - Run migrations: `alembic upgrade head`

3. **API Changes**:
   - Update router endpoints
   - Update Pydantic schemas
   - Update API documentation
   - Add tests for new endpoints

## Testing

### Frontend Tests

```bash
npm test                    # Run all tests
npm run test:watch          # Watch mode
npm run test:coverage       # Coverage report
npm run test:ci             # CI mode
```

### Backend Tests

```bash
pytest                      # Run all tests
pytest api/tests/          # Run specific directory
pytest -v                  # Verbose output
pytest --cov=api           # With coverage
pytest -m unit             # Run unit tests only
pytest -m integration      # Run integration tests only
```

### Test Coverage

Target: **80%+ coverage**

Reports are generated in:
- Frontend: `coverage/` directory
- Backend: `htmlcov/` directory

## API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## Health Checks

Monitor application health:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/health/detailed
curl http://localhost:8000/health/database
curl http://localhost:8000/health/storage
curl http://localhost:8000/metrics
```

## Deployment

### Environment-Specific Configuration

- **Development**: Full logging, debug mode, local services
- **Staging**: Production-like with test data
- **Production**: Optimized performance, security hardening

### Docker Deployment

```dockerfile
# Backend
FROM python:3.11-slim
COPY api/ /app/api/
WORKDIR /app
RUN pip install -r requirements.txt
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Frontend
FROM node:18-alpine
COPY . /app
WORKDIR /app
RUN npm install && npm run build
CMD ["npm", "start"]
```

### Vercel Deployment

The project includes `vercel.json` for frontend deployment to Vercel.

## Security Features

- **Authentication**: JWT-based with refresh tokens
- **Authorization**: Role-based access control
- **Input Validation**: Comprehensive input sanitization
- **Rate Limiting**: Per-user and per-IP limits
- **Security Headers**: HSTS, CSP, X-Frame-Options
- **Data Encryption**: Sensitive data encryption at rest

## Performance Features

- **Connection Pooling**: Efficient database connections
- **Caching**: Redis-based caching system
- **Async Operations**: Non-blocking I/O operations
- **Query Optimization**: Database query optimization
- **Load Balancing**: Horizontal scaling support

## Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Verify PostgreSQL is running
   - Check `DATABASE_URL` in `.env`
   - Ensure database exists

2. **S3 Storage Errors**:
   - Verify AWS credentials in `.env`
   - Check S3 bucket permissions
   - Verify bucket exists

3. **AI Service Connection Issues**:
   - Check ComfyUI/RunPod service URLs
   - Verify API keys are correct
   - Check network connectivity

4. **Port Already in Use**:
   - Change ports in `.env`
   - Kill existing processes: `lsof -ti:8000 | xargs kill`

### Logs

- **Backend**: Check `server.log` or console output
- **Frontend**: Check browser console and terminal output
- **Structured Logs**: Available in `logs/` directory

## Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Follow the architecture patterns** and code standards
4. **Add comprehensive tests** for new features
5. **Update documentation** as needed
6. **Commit your changes**: `git commit -m 'Add amazing feature'`
7. **Push to the branch**: `git push origin feature/amazing-feature`
8. **Submit a pull request**

### Code Review Checklist

- [ ] TypeScript types are properly defined
- [ ] Components are properly tested
- [ ] Business logic is in services/hooks
- [ ] Memory management is handled
- [ ] Performance optimizations are applied
- [ ] Documentation is updated
- [ ] Linting passes
- [ ] Tests pass with good coverage

## Additional Resources

- [Frontend Documentation](./src/README.md)
- [Backend API Documentation](./api/README.md)
- [Models Documentation](./api/models/README.md)
- [Routers Documentation](./api/routers/README.md)
- [Services Documentation](./api/services/README.md)
- [Storage Hooks Documentation](./src/hooks/storage/README.md)

### External Documentation

- [Next.js Documentation](https://nextjs.org/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [React Documentation](https://react.dev/)

## License

[Add your license here]

## Support

For questions, issues, or contributions:
- Create an issue in the repository
- Check existing documentation
- Review module-specific README files
- Contact the development team

---

**Built with ❤️ for scalable, maintainable, and performant full-stack development.**

