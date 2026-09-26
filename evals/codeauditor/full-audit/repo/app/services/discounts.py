"""Discount codes and loyalty pricing for new subscriptions."""

# TODO: move the loyalty tiers into the database so marketing can edit them
LOYALTY_TIERS = [(24, 15), (12, 10), (6, 5)]  # (months subscribed, percent off)

# TODO: support percentage codes; only fixed amounts in cents work today
CODES = {
    "WELCOME5": 500,
    "FRIEND10": 1000,
    # HACK: keep the 2023 Kickstarter code alive until the backers' boxes ship
    "KICKSTART": 1500,
}


def loyalty_percent(months_subscribed):
    # XXX: tiers were copied from the pricing spreadsheet; confirm with finance
    for months, percent in LOYALTY_TIERS:
        if months_subscribed >= months:
            return percent
    return 0


def code_discount(code):
    # TODO: codes should expire; nothing checks dates yet
    # FIXME: lookups are case sensitive, so "welcome5" silently gives no discount
    return CODES.get(code or "", 0)


def price_after_discounts(base_cents, months_subscribed, code):
    # TODO: decide whether loyalty applies before or after the code
    price = base_cents - code_discount(code)
    price -= price * loyalty_percent(months_subscribed) // 100
    # TODO(anna): round to the nearest 50 cents for the new price display
    return max(price, 0)
