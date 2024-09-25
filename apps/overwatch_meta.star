"""
Applet: Overwatch Meta
Summary: Overatch 2 Meta Statistics
Description: This app polls the Overwatch 2 Meta information from Overbuff.
Author: GeoffBarrett
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

DEFAULT_WHO = "world"

def main(config):
    who = config.str("who", DEFAULT_WHO)
    message = "Hello, {}!".format(who)
    return render.Root(
        child = render.Text(message),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "who",
                name = "Who?",
                desc = "Who to say hello to.",
                icon = "user",
            ),
        ],
    )
