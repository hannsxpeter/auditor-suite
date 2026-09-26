import click
from flask import Flask

from app import config
from app.models import db
from app.routes import customers, health, reports, subscriptions, webhooks
from app.services import billing


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.update(config.from_env() if test_config is None else test_config)
    db.init_app(app)

    for module in (customers, subscriptions, reports, webhooks, health):
        app.register_blueprint(module.bp)

    @app.cli.command("init-db")
    def init_db():
        """Create the tables on a new, empty database."""
        db.create_all()

    @app.cli.command("renew")
    def renew():
        """Charge every subscription whose renewal date has arrived."""
        count = billing.run_renewals()
        click.echo(f"renewed {count} subscription(s)")

    return app
