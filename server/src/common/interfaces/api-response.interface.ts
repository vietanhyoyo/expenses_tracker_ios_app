export interface ServiceResponse<T> {
  message: string;
  data: T;
}

export interface ApiResponse<T> extends ServiceResponse<T> {
  statusCode: number;
}
