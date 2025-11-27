/**
 * Example: Custom Metrics Exporter for Eivan Pay
 * 
 * This file shows how to add custom business metrics to your NestJS application.
 * Copy the relevant parts to your services.
 */

import { Injectable } from '@nestjs/common';
import { Counter, Histogram, Gauge, Registry } from 'prom-client';

@Injectable()
export class EivanPayMetricsService {
  private registry = new Registry();

  // ==================== Loan Request Metrics ====================
  private loanRequestsCounter = new Counter({
    name: 'eivan_pay_loan_requests_total',
    help: 'Total number of loan requests',
    labelNames: ['status', 'channel'],
    registers: [this.registry],
  });

  private loanRequestsAmountCounter = new Counter({
    name: 'eivan_pay_loan_requests_amount_total',
    help: 'Total amount of loan requests',
    labelNames: ['status'],
    registers: [this.registry],
  });

  private loanRequestDuration = new Histogram({
    name: 'eivan_pay_loan_requests_duration_seconds',
    help: 'Duration of loan request processing',
    labelNames: ['status'],
    buckets: [0.1, 0.5, 1, 2, 5, 10, 30],
    registers: [this.registry],
  });

  // ==================== Loan Metrics ====================
  private loansGauge = new Gauge({
    name: 'eivan_pay_loans_total',
    help: 'Total number of active loans',
    registers: [this.registry],
  });

  private loansAmountGauge = new Gauge({
    name: 'eivan_pay_loans_total_amount',
    help: 'Total amount of active loans',
    registers: [this.registry],
  });

  private loansByStatusGauge = new Gauge({
    name: 'eivan_pay_loans_by_status',
    help: 'Number of loans by status',
    labelNames: ['status'],
    registers: [this.registry],
  });

  // ==================== Payment Metrics ====================
  private paymentsCounter = new Counter({
    name: 'eivan_pay_payments_total',
    help: 'Total number of payments',
    labelNames: ['status', 'method'],
    registers: [this.registry],
  });

  private paymentsAmountCounter = new Counter({
    name: 'eivan_pay_payments_amount_total',
    help: 'Total amount of payments',
    labelNames: ['status', 'method'],
    registers: [this.registry],
  });

  private paymentDuration = new Histogram({
    name: 'eivan_pay_payments_duration_seconds',
    help: 'Duration of payment processing',
    labelNames: ['status', 'method'],
    buckets: [0.1, 0.5, 1, 2, 5, 10],
    registers: [this.registry],
  });

  // ==================== Settlement Metrics ====================
  private settlementsCounter = new Counter({
    name: 'eivan_pay_settlements_total',
    help: 'Total number of settlements',
    labelNames: ['status'],
    registers: [this.registry],
  });

  private settlementsAmountCounter = new Counter({
    name: 'eivan_pay_settlements_amount_total',
    help: 'Total amount of settlements',
    labelNames: ['status'],
    registers: [this.registry],
  });

  private settlementsPendingGauge = new Gauge({
    name: 'eivan_pay_settlements_pending',
    help: 'Number of pending settlements',
    registers: [this.registry],
  });

  private settlementDuration = new Histogram({
    name: 'eivan_pay_settlements_duration_seconds',
    help: 'Duration of settlement processing',
    labelNames: ['status'],
    buckets: [1, 5, 10, 30, 60, 300],
    registers: [this.registry],
  });

  // ==================== Credit Check Metrics ====================
  private creditChecksCounter = new Counter({
    name: 'eivan_pay_credit_checks_total',
    help: 'Total number of credit checks',
    labelNames: ['status', 'grade'],
    registers: [this.registry],
  });

  private creditCheckDuration = new Histogram({
    name: 'eivan_pay_credit_checks_duration_seconds',
    help: 'Duration of credit check processing',
    labelNames: ['status', 'grade'],
    buckets: [0.5, 1, 2, 5, 10, 30],
    registers: [this.registry],
  });

  // ==================== Wallet Metrics ====================
  private walletsGauge = new Gauge({
    name: 'eivan_pay_wallets_total',
    help: 'Total number of wallets',
    labelNames: ['status'],
    registers: [this.registry],
  });

  private walletBalanceGauge = new Gauge({
    name: 'eivan_pay_wallet_balance_total',
    help: 'Total wallet balance',
    registers: [this.registry],
  });

  private walletBalanceAvgGauge = new Gauge({
    name: 'eivan_pay_wallet_balance_avg',
    help: 'Average wallet balance',
    registers: [this.registry],
  });

  private walletTransactionsCounter = new Counter({
    name: 'eivan_pay_wallet_transactions_total',
    help: 'Total number of wallet transactions',
    labelNames: ['type', 'status'],
    registers: [this.registry],
  });

  private walletTransactionsAmountCounter = new Counter({
    name: 'eivan_pay_wallet_transactions_amount_total',
    help: 'Total amount of wallet transactions',
    labelNames: ['type', 'status'],
    registers: [this.registry],
  });

  // ==================== Cheque Metrics ====================
  private chequesCounter = new Counter({
    name: 'eivan_pay_cheques_total',
    help: 'Total number of cheques',
    labelNames: ['status'],
    registers: [this.registry],
  });

  private chequesAmountCounter = new Counter({
    name: 'eivan_pay_cheques_amount_total',
    help: 'Total amount of cheques',
    labelNames: ['status'],
    registers: [this.registry],
  });

  // ==================== Security Metrics ====================
  private authAttemptsCounter = new Counter({
    name: 'eivan_pay_auth_attempts_total',
    help: 'Total number of authentication attempts',
    labelNames: ['status', 'type'],
    registers: [this.registry],
  });

  private rateLimitHitsCounter = new Counter({
    name: 'eivan_pay_rate_limit_hits_total',
    help: 'Total number of rate limit hits',
    labelNames: ['endpoint', 'ip'],
    registers: [this.registry],
  });

  private securityEventsCounter = new Counter({
    name: 'eivan_pay_security_events_total',
    help: 'Total number of security events',
    labelNames: ['type'],
    registers: [this.registry],
  });

  // ==================== Public Methods ====================

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

  // Loan Methods
  setLoansCount(count: number) {
    this.loansGauge.set(count);
  }

  setLoansAmount(amount: number) {
    this.loansAmountGauge.set(amount);
  }

  setLoansByStatus(status: string, count: number) {
    this.loansByStatusGauge.set({ status }, count);
  }

  // Payment Methods
  incrementPayment(status: string, method: string, amount?: number) {
    this.paymentsCounter.inc({ status, method });
    if (amount) {
      this.paymentsAmountCounter.inc({ status, method }, amount);
    }
  }

  recordPaymentDuration(status: string, method: string, duration: number) {
    this.paymentDuration.observe({ status, method }, duration);
  }

  // Settlement Methods
  incrementSettlement(status: string, amount?: number) {
    this.settlementsCounter.inc({ status });
    if (amount) {
      this.settlementsAmountCounter.inc({ status }, amount);
    }
  }

  setSettlementsPending(count: number) {
    this.settlementsPendingGauge.set(count);
  }

  recordSettlementDuration(status: string, duration: number) {
    this.settlementDuration.observe({ status }, duration);
  }

  // Credit Check Methods
  incrementCreditCheck(status: string, grade: string) {
    this.creditChecksCounter.inc({ status, grade });
  }

  recordCreditCheckDuration(status: string, grade: string, duration: number) {
    this.creditCheckDuration.observe({ status, grade }, duration);
  }

  // Wallet Methods
  setWalletsCount(status: string, count: number) {
    this.walletsGauge.set({ status }, count);
  }

  setWalletBalance(total: number, avg: number) {
    this.walletBalanceGauge.set(total);
    this.walletBalanceAvgGauge.set(avg);
  }

  incrementWalletTransaction(type: string, status: string, amount?: number) {
    this.walletTransactionsCounter.inc({ type, status });
    if (amount) {
      this.walletTransactionsAmountCounter.inc({ type, status }, amount);
    }
  }

  // Cheque Methods
  incrementCheque(status: string, amount?: number) {
    this.chequesCounter.inc({ status });
    if (amount) {
      this.chequesAmountCounter.inc({ status }, amount);
    }
  }

  // Security Methods
  incrementAuthAttempt(status: string, type: string) {
    this.authAttemptsCounter.inc({ status, type });
  }

  incrementRateLimitHit(endpoint: string, ip: string) {
    this.rateLimitHitsCounter.inc({ endpoint, ip });
  }

  incrementSecurityEvent(type: string) {
    this.securityEventsCounter.inc({ type });
  }

  // Get metrics registry
  getRegistry(): Registry {
    return this.registry;
  }

  // Get metrics as string (for /metrics endpoint)
  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }
}








