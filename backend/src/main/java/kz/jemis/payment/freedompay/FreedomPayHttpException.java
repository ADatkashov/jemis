package kz.jemis.payment.freedompay;

/** A Freedom Pay HTTP-level failure: network error, timeout, non-2xx status or a body that is not the expected XML. */
public class FreedomPayHttpException extends RuntimeException {

    public FreedomPayHttpException(String message) {
        super(message);
    }

    public FreedomPayHttpException(String message, Throwable cause) {
        super(message, cause);
    }
}
