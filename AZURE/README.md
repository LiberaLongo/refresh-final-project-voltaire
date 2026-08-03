- ``` > Azure Functions: Create New Project ... ```
- **browse folder** or dan002-voltaire
- **Python** or other languages
- python **3.14.4** or other versions
- http_trigger, **timer_trigger** or other triggers
- name of function
- cron expression:
	Enter a cron expression of the format
	'{second} {minute} {hour} {day} {month} {day of week}'
	to specify the schedule.
	
Azure Functions TimerTrigger uses NCRONTAB, not standard Unix cron.

Common examples:
| Schedule					| NCRONTAB    |
|---------------------------|-------------|
| Every minute				| 0 * * * * * |
| Every hour				| 0 0 * * * * |
| Every day at midnight		| 0 0 0 * * * |
| First day of every month	| 0 0 0 1 * * |
| January 1 every year		| 0 0 0 1 1 * |
	
I choosed every day at midnight 0 0 0 * * *

to generate requirements.txt:\
```uv export --format requirements.txt --output-file requirements.txt```

to deploy to azure function app from command line:\
```func azure functionapp publish fn-volt-bollettini --build remote```
