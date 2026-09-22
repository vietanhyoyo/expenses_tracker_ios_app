import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Request, Response } from 'express';
import { ErrorCode } from '../constants/error-codes.constant';
import { ApiException } from '../exceptions/api.exception';

interface ErrorBody {
  statusCode: number;
  errorCode: string;
  message: string;
  errors?: unknown;
  timestamp: string;
  path: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const response = http.getResponse<Response>();
    const request = http.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let errorCode: string = ErrorCode.INTERNAL_SERVER_ERROR;
    let message = 'An unexpected error occurred';
    let errors: unknown;

    if (exception instanceof ApiException) {
      status = exception.getStatus();
      errorCode = exception.errorCode;
      message = exception.message;
      errors = exception.errors;
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      errorCode =
        status === HttpStatus.UNAUTHORIZED
          ? ErrorCode.UNAUTHORIZED
          : status === HttpStatus.FORBIDDEN
            ? ErrorCode.FORBIDDEN
            : ErrorCode.VALIDATION_ERROR;
      message =
        typeof body === 'object' && body !== null && 'message' in body
          ? String(body.message)
          : exception.message;
    } else if (
      exception instanceof Prisma.PrismaClientKnownRequestError &&
      exception.code === 'P2002'
    ) {
      status = HttpStatus.CONFLICT;
      errorCode = ErrorCode.VALIDATION_ERROR;
      message = 'A unique value already exists';
    } else {
      this.logger.error(
        'Unexpected request failure',
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    const body: ErrorBody = {
      statusCode: status,
      errorCode,
      message,
      timestamp: new Date().toISOString(),
      path: request.originalUrl,
    };
    if (errors !== undefined) body.errors = errors;
    response.status(status).json(body);
  }
}
