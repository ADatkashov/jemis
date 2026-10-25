package kz.jemis.payment;

/** Used both for a payment attempt and, aggregated, for the order (SUCCEEDED == paid). */
public enum PaymentStatus { PENDING, SUCCEEDED, FAILED, CANCELLED, REFUNDED }
