/**
 * Example: How to integrate Prometheus metrics in NestJS
 * 
 * This file shows a complete example of adding metrics to your NestJS application
 * Copy relevant parts to your services.
 */

import { Module } from '@nestjs/common';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';
import { Counter, Histogram, Gauge } from 'prom-client';

// ==================== 1. Setup Prometheus Module ====================

@Module({
  imports: [
    PrometheusModule.register({
      path: '/metrics',
      defaultMetrics: {
        enabled: true,
      },
      controller: {
        path: '/metrics',
      },
    }),
  ],
})
export class AppModule {}

// ==================== 2. Create Metrics Service ====================

import { Injectable } from '@nestjs/common';
import { InjectMetric } from '@willsoto/nestjs-prometheus';

@Injectable()
export class MetricsService {
  constructor(
    // Loan Request Metrics
    @InjectMetric('eivan_pay_loan_requests_total')
    private loanRequestsCounter: Counter<string>,
    
    @InjectMetric('eivan_pay_loan_requests_amount_total')
    private loanRequestsAmountCounter: Counter<string>,
    
    @InjectMetric('eivan_pay_loan_requests_duration_seconds')
    private loanRequestDuration: Histogram<string>,
    
    // Payment Metrics
    @InjectMetric('eivan_pay_payments_total')
    private paymentsCounter: Counter<string>,
    
    @InjectMetric('eivan_pay_payments_amount_total')
    private paymentsAmountCounter: Counter<string>,
    
    // Wallet Metrics
    @InjectMetric('eivan_pay_wallet_balance_total')
    private walletBalanceGauge: Gauge<string>,
  ) {}

  // Loan Request Methods
  incrementLoanRequest(status: string, channel: string, amount?: number) {
    this.loanRequestsCounter.inc({ status, channel });
    if (amount) {
      this.loanRequestsAmountCounter.inc({ status }, amount);
    }
  }

  recordLoanRequestDuration(status: string, duration: number) {
    this.loanRequestDuration.observe({ status }, duration);
  }

  // Payment Methods
  incrementPayment(status: string, method: string, amount?: number) {
    this.paymentsCounter.inc({ status, method });
    if (amount) {
      this.paymentsAmountCounter.inc({ status, method }, amount);
    }
  }

  // Wallet Methods
  setWalletBalance(balance: number) {
    this.walletBalanceGauge.set(balance);
  }
}

// ==================== 3. Register Metrics ====================

import { makeCounter, makeHistogram, makeGauge } from '@willsoto/nestjs-prometheus';

export const loanRequestsCounter = makeCounter({
  name: 'eivan_pay_loan_requests_total',
  help: 'Total number of loan requests',
  labelNames: ['status', 'channel'],
});

export const loanRequestDuration = makeHistogram({
  name: 'eivan_pay_loan_requests_duration_seconds',
  help: 'Duration of loan request processing',
  labelNames: ['status'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 30],
});

export const walletBalanceGauge = makeGauge({
  name: 'eivan_pay_wallet_balance_total',
  help: 'Total wallet balance',
});

// ==================== 4. Use in Service ====================

import { Injectable } from '@nestjs/common';

@Injectable()
export class LoanRequestService {
  constructor(private metricsService: MetricsService) {}

  async createLoanRequest(dto: CreateLoanRequestDto) {
    const startTime = Date.now();
    
    try {
      // ... business logic ...
      
      const duration = (Date.now() - startTime) / 1000;
      this.metricsService.incrementLoanRequest('success', 'pwa', dto.amount);
      this.metricsService.recordLoanRequestDuration('success', duration);
      
      return result;
    } catch (error) {
      const duration = (Date.now() - startTime) / 1000;
      this.metricsService.incrementLoanRequest('failed', 'pwa');
      this.metricsService.recordLoanRequestDuration('failed', duration);
      throw error;
    }
  }
}

// ==================== 5. Use Interceptor for Automatic Metrics ====================

import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const startTime = Date.now();
    const method = request.method;
    const route = request.route?.path || 'unknown';

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = (Date.now() - startTime) / 1000;
          // Record metrics
          this.metricsService.recordRequestDuration(method, route, 'success', duration);
        },
        error: () => {
          const duration = (Date.now() - startTime) / 1000;
          this.metricsService.recordRequestDuration(method, route, 'error', duration);
        },
      }),
    );
  }
}

// ==================== 6. Setup in main.ts ====================

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MetricsInterceptor } from './common/interceptors/metrics.interceptor';
import { MetricsService } from './common/services/metrics.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Add metrics interceptor globally
  const metricsService = app.get(MetricsService);
  app.useGlobalInterceptors(new MetricsInterceptor(metricsService));
  
  await app.listen(3000);
}
bootstrap();








