package kz.jemis.common;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class MoneyTest {
    @Test
    void weightedLineTotalIsExactInMinorUnits() {
        // 790.00 KZT/kg * 1.5 kg = 1185.00 KZT
        assertThat(Money.lineTotal(79_000, 1_500)).isEqualTo(118_500);
    }

    @Test
    void roundsHalfUpToWholeTiyn() {
        // 0.01 KZT/kg * 0.5 kg = 0.005 KZT -> 1 tiyn? 1 * 500 = 500 -> (500+500)/1000 = 1
        assertThat(Money.lineTotal(1, 500)).isEqualTo(1);
        assertThat(Money.lineTotal(1, 499)).isEqualTo(0);
        assertThat(Money.lineTotal(333, 1_000)).isEqualTo(333);
        assertThat(Money.lineTotal(333, 3_000)).isEqualTo(999);
    }

    @Test
    void percentRoundsHalfUp() {
        assertThat(Money.percentOf(10_050, 10)).isEqualTo(1_005);
        assertThat(Money.percentOf(105, 10)).isEqualTo(11); // 10.5 -> 11
        assertThat(Money.percentOf(104, 10)).isEqualTo(10);
    }

    @Test
    void noFloatingPointDrift() {
        long sum = 0;
        for (int i = 0; i < 1000; i++) sum += Money.lineTotal(10, 1_000); // 0.10 KZT x 1000
        assertThat(sum).isEqualTo(10_000);
    }
}
