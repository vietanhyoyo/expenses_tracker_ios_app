import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { useContainer, ValidationError } from 'class-validator';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ErrorCode } from './common/constants/error-codes.constant';
import { ApiException, FieldError } from './common/exceptions/api.exception';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';

function flattenValidationErrors(
  validationErrors: ValidationError[],
  parent = '',
): FieldError[] {
  return validationErrors.flatMap((error) => {
    const field = parent ? `${parent}.${error.property}` : error.property;
    const own = Object.values(error.constraints ?? {}).map((message) => ({
      field,
      message,
    }));
    return [...own, ...flattenValidationErrors(error.children ?? [], field)];
  });
}

export async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  useContainer(app.select(AppModule), { fallbackOnErrors: true });
  app.setGlobalPrefix('api/v1');
  app.use(helmet());
  const corsOrigin = process.env.CORS_ORIGIN ?? '*';
  app.enableCors({
    origin:
      corsOrigin === '*'
        ? true
        : corsOrigin.split(',').map((origin) => origin.trim()),
    credentials: corsOrigin !== '*',
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) =>
        new ApiException(
          ErrorCode.VALIDATION_ERROR,
          'Invalid request data',
          400,
          flattenValidationErrors(errors),
        ),
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Expense Tracker API')
    .setDescription(
      'REST API for authentication, accounts, categories, transactions, expenses, and dashboard summaries',
    )
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
  });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  Logger.log(`Expense Tracker API listening on port ${port}`, 'Bootstrap');
}

void bootstrap();
