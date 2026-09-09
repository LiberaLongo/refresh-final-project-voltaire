import logging
import azure.functions as func
from main import bollettino_arpae, up_bollettini, forecast

app = func.FunctionApp()

'''
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
'''

# seconda funzione per test (_tiziano_)
@app.route(route="http_trigger_azione_manuale", auth_level=func.AuthLevel.FUNCTION)
def http_trigger_azione_manuale(req: func.HttpRequest) -> func.HttpResponse:
	logging.info('trigger http azione manuale')

# eseguo un codice parallelo per debuggare la connessione al db
	azione = req.params.get("azione")
	if azione == "forecast": forecast()
	elif azione == "bollettino": bollettino_arpae()
	elif azione == "update_bollettini": up_bollettini()
	else: logging.info("nessuna azione eseguita")
	
	return func.HttpResponse(
		"trigger http 2 terminata correttamente.",
		status_code=200
	)

# seconda funzione per scarico giornaliero dati misure

@app.timer_trigger(
#esecuzione giornaliera scarico del bollettino ARPAE
	schedule="0 30 6 * * *",
	arg_name="timer",
	run_on_startup=False,
	use_monitor=True
)
def update_bollettino(timer: func.TimerRequest) -> None:
	logging.info("Esecuzione job giornaliero")
	bollettino_arpae()  # Esegui la funzione per il job giornaliero
	logging.info("Job giornaliero completato")

'''@app.timer_trigger(
# esecuzione giornaliera update tabella bollettini
# eseguita dopo lo scarico del bollettino
	schedule="0 20 1 * * *",
	arg_name="timer",
	run_on_startup=False,
	use_monitor=True
)
def update_bollettini(timer: func.TimerRequest) -> None:
	logging.info("Esecuzione update bollettini")
#    up_bollettini()  # Esegui la funzione per update bollettini
	logging.info("update bollettini completato")

'''

@app.timer_trigger(
# esecuzione giornaliera update forecast pm10
# set di debug ogni ora alle xx:30
# probabilmente i dati di forecast vengono resi disponibili tra le 8 e le 10 UTC
	schedule="0 30 8 * * *",
	arg_name="timer",
	run_on_startup=False,
	use_monitor=True
)
def update_forecast(timer: func.TimerRequest) -> None:
	logging.info("Esecuzione update forecast")
	forecast()  # Esegui la funzione per update bollettini
	logging.info("update forecast completato")
