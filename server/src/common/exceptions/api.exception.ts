import { HttpException, HttpStatus } from '@nestjs/common';
import type { ErrorCodeValue } from '../constants/error-codes.constant';

export interface FieldError {
  field: string;
  message: string;
}

export class ApiException extends HttpException {
  constructor(
    public readonly errorCode: ErrorCodeValue,
    message: string,
    status: HttpStatus,
    public readonly errors?: FieldError[],
  ) {
    super(message, status);
  }
}
