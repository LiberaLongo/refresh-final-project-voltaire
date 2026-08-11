import logging
import azure.functions as func
from main import my_main

# aggiunta TT
from main_debug import my_main_debug

app = func.FunctionApp()

# funzione lanciata "ogni giorno"
# (disattivata in locale)
@app.timer_trigger(schedule="0 0 0 * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def timer_trigger(myTimer: func.TimerRequest) -> None:

    if myTimer.past_due:
        logging.info('The timer is past due!')

    logging.info("start")

    # my code here
    my_main()

    logging.info("end")

# funzione per test
@app.route(route="http_trigger", auth_level=func.AuthLevel.FUNCTION)
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    logging.info("start - richiamo della funzione my_main()")
    my_main()
    logging.info("end - richiamo della funzione my_main()")

    return func.HttpResponse(
        "my_main worked properly.",
        status_code=200
    )

# seconda funzione per test (_tiziano_)
@app.route(route="http_trigger2_test_tt", auth_level=func.AuthLevel.FUNCTION)
def http_trigger2_test_tt(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('trigger http 2 di test')

# eseguo un codice parallelo per debuggare la connesione al db
    my_main_debug()

    return func.HttpResponse(
        "trigger http 2 terminata correttamente.",
        status_code=200
    )

