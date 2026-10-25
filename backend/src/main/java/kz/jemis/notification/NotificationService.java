package kz.jemis.notification;

import java.util.Map;
import java.util.UUID;
import kz.jemis.common.I18n;
import kz.jemis.identity.User;
import kz.jemis.identity.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {
    private record Text(String ru, String kk, String en) {
        String of(String lang) { return I18n.pick(lang, ru, kk, en); }
    }

    private static final Map<String, Text[]> TEXTS = Map.of(
            "ORDER_CONFIRMED", new Text[]{
                    new Text("Заказ оформлен", "Тапсырыс рәсімделді", "Order placed"),
                    new Text("Заказ №%s принят в обработку.", "№%s тапсырыс өңдеуге қабылданды.", "Order #%s has been received.")},
            "PAYMENT_SUCCEEDED", new Text[]{
                    new Text("Оплата получена", "Төлем қабылданды", "Payment received"),
                    new Text("Заказ №%s оплачен.", "№%s тапсырыс төленді.", "Order #%s is paid.")},
            "PAYMENT_FAILED", new Text[]{
                    new Text("Оплата не прошла", "Төлем өтпеді", "Payment failed"),
                    new Text("Не удалось оплатить заказ №%s. Попробуйте ещё раз.", "№%s тапсырысты төлеу мүмкін болмады. Қайталап көріңіз.", "Payment for order #%s failed. Please try again.")},
            "ORDER_PREPARING", new Text[]{
                    new Text("Заказ собирается", "Тапсырыс жиналып жатыр", "Order is being prepared"),
                    new Text("Мы собираем заказ №%s.", "№%s тапсырыс жиналып жатыр.", "We are preparing order #%s.")},
            "COURIER_ASSIGNED", new Text[]{
                    new Text("Курьер назначен", "Курьер тағайындалды", "Courier assigned"),
                    new Text("Курьер назначен на заказ №%s.", "№%s тапсырысқа курьер тағайындалды.", "A courier was assigned to order #%s.")},
            "ORDER_ON_THE_WAY", new Text[]{
                    new Text("Курьер в пути", "Курьер жолда", "Courier is on the way"),
                    new Text("Заказ №%s уже едет к вам.", "№%s тапсырыс сізге келе жатыр.", "Order #%s is on its way to you.")},
            "ORDER_DELIVERED", new Text[]{
                    new Text("Заказ доставлен", "Тапсырыс жеткізілді", "Order delivered"),
                    new Text("Заказ №%s доставлен. Приятного аппетита!", "№%s тапсырыс жеткізілді. Ас болсын!", "Order #%s was delivered. Enjoy!")},
            "ORDER_CANCELLED", new Text[]{
                    new Text("Заказ отменён", "Тапсырыс бас тартылды", "Order cancelled"),
                    new Text("Заказ №%s отменён.", "№%s тапсырыс бас тартылды.", "Order #%s was cancelled.")});

    private final NotificationRepository repo;
    private final UserRepository users;
    private final PushProvider push;

    public NotificationService(NotificationRepository repo, UserRepository users, PushProvider push) {
        this.repo = repo;
        this.users = users;
        this.push = push;
    }

    /** Stores an in-app notification in the recipient's language; push is attempted only if a provider is configured. */
    @Transactional(propagation = Propagation.REQUIRED)
    public void orderEvent(UUID userId, String type, String orderNumber, UUID orderId) {
        Text[] t = TEXTS.get(type);
        if (t == null) return;
        User u = users.findById(userId).orElse(null);
        if (u == null) return;
        String lang = I18n.lang(java.util.Locale.forLanguageTag(u.getLocale()));
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(t[0].of(lang));
        n.setBody(t[1].of(lang).formatted(orderNumber));
        n.setOrderId(orderId);
        if (push.isConfigured() && u.isNotifyOrders()) {
            n.setPushAttempts(1);
            n.setPushState(push.send(u, n.getTitle(), n.getBody()) ? "SENT" : "FAILED");
        }
        repo.save(n);
    }
}
