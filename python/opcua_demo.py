# Importieren der benötigten Module
import random
import threading
import RPi.GPIO as GPIO  # GPIO-Bibliothek zur Steuerung der Raspberry Pi GPIO-Pins
import time  # Modul zum Arbeiten mit Zeit

# Module für OPCUA
from opcua import ua, uamethod, Server  # OPC UA-Bibliothek zur Implementierung eines OPC UA-Servers
from opcua.ua import ObjectIds  # OPC UA-Objekt-IDs
import datetime  # Modul zum Arbeiten mit Datum und Zeit

# Festlegen des Modus für die GPIO-Pins
GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

reset_cooldown = 600
status_led_duration = 2

# Listen für GPIOs und Schalterzustände 
outputs = [10, 8, 12, 16, 18]  # Liste der Ausgangspins
switch = [False, False, False, False, 0]  # Liste zum Speichern der Schalterzustände

# Liste für Initialzustände
switch_old = switch  # Liste zum Speichern der vorherigen Schalterzustände

# Zeitpunkt für den letzten Blink-Status
lastBlink = datetime.datetime.now()
blink_interval = 5
disko_interval = 1

# Initialisieren der Ausgangspins
for value in outputs:
    GPIO.setup(value, GPIO.OUT)

# Erstellen und Konfigurieren des OPC UA-Servers
server=Server()  # Erstellen einer Serverinstanz
url="opc.tcp://0.0.0.0:4840" # Festlegen der URL für den Server
server.set_endpoint(url)  # Einstellen der URL als Endpoint des Servers
last_opc_interaction = datetime.datetime.now()

# Registrieren eines Namespace im Server
name="OPCUA_Serverraum"  # Name des Namespace
addspace=server.register_namespace(name)  # Registrieren des Namespace im Server

# Hinzufügen eines Objekts zum Server
node= server.get_objects_node()  # Erhalten des Objektknotens des Servers
Raspi=node.add_object(addspace,"Raspi")  # Hinzufügen eines Objekts namens "Raspi" zum Server

# Hinzufügen eines Ordners zum Objekt
myfolder = Raspi.add_folder(addspace, "Schalter")  # Hinzufügen eines Ordners namens "Schalter" zum Objekt "Raspi"

# Hinzufügen von Variablen zum Ordner
# Jeder Schalter bekommt eine eigene Variable, die seinen Zustand repräsentiert
# "timestamp" ist eine Variable, die den Zeitpunkt der letzten Änderung aufzeichnet
switch1 = myfolder.add_variable(addspace,"S1: LED anschalten / ausschalten",False)
switch2 = myfolder.add_variable(addspace,"S2: LED die Farbe Rot hinzufügen / entfernen",False)
switch3 = myfolder.add_variable(addspace,"S3: LED die Farbe Grün hinzufügen / entfernen",False)
switch4 = myfolder.add_variable(addspace,"S4: Diskomodus anschalten / ausschalten",False)
switch5 = myfolder.add_variable(addspace,"S5: Blink-Geschwindigkeit der LED angeben (0-3)",0)
timestamp = node.add_variable(addspace,"Zeitpunkt der letzten Änderung",0)

# Setzen der Variablen auf beschreibbar
# Dies ermöglicht das Ändern der Variablenwerte zur Laufzeit
switch1.set_writable()
switch2.set_writable()
switch3.set_writable()
switch4.set_writable()
switch5.set_writable()
# timestamp.set_writable()

# Starten des Servers und Ausgeben der URL
server.start()
print("Server startet auf {}",format(url))

def reset_led():
    global switch
    switch = [False,False,False,False,0]
    switch1.set_value(False)
    switch2.set_value(False)
    switch3.set_value(False)
    switch4.set_value(False)
    switch5.set_value(0)

def blink_led(led_pin=0):
    GPIO.output(led_pin, GPIO.HIGH)
    time.sleep(status_led_duration)
    GPIO.output(led_pin, GPIO.LOW)

# Funktion zum Überprüfen und Setzen von Schalterwerten
def validate_and_set(switch_variable, value, lower_limit=0, upper_limit=1):
    global outputs
    global switch
    if value < lower_limit or value > upper_limit:
        print(f"Illegal value {value} provided, resetting everything to 0.")
        blink_led(18)
        reset_led()
        return 0
    else:
        switch_variable.set_value(value)
        return value
    
last_disko_time = datetime.datetime.now()
def disko_mode(disko_interval = 1):
    global last_disko_time
    color = newcolor = 4    
    if (datetime.datetime.now() - lastBlink).total_seconds() > disko_interval:
        last_disko_time = datetime.datetime.now()
        while color == newcolor:
            newcolor = random.randint(1,4)
        color = newcolor
        if color == 1: 
            GPIO.output(outputs[1], GPIO.HIGH); GPIO.output(outputs[2], GPIO.HIGH)
            switch2.set_value(1); switch3.set_value(1)
        elif color == 2:
            GPIO.output(outputs[1], GPIO.LOW); GPIO.output(outputs[2], GPIO.HIGH)
            switch2.set_value(0); switch3.set_value(1)
        elif color == 3:
            GPIO.output(outputs[1], GPIO.HIGH); GPIO.output(outputs[2], GPIO.LOW)
            switch2.set_value(1); switch3.set_value(0)
        elif color == 4:
            GPIO.output(outputs[1], GPIO.LOW); GPIO.output(outputs[2], GPIO.LOW)
            switch2.set_value(0); switch3.set_value(0)

# Hauptloop des Programms
while True:

    # Überprüfen der Zustände der Schalter im OPC UA-Server und Aktualisieren der Ausgangspins und der switch-Liste entsprechend
    switch[0] = validate_and_set(switch1, switch1.get_value())
    switch[1] = validate_and_set(switch2, switch2.get_value())
    switch[2] = validate_and_set(switch3, switch3.get_value())
    switch[3] = validate_and_set(switch4, switch4.get_value())
    switch[4] = validate_and_set(switch5, switch5.get_value(), upper_limit=3)

    for i in range(len(outputs) - 2):
        if switch[i] == 1 and GPIO.input(18) != GPIO.HIGH:  # Wenn Schalter aktiv und kein Fehler
            if i == 0:
                if switch[3] == 1:
                    disko_mode()
                if switch[4] != 0:  # Blinkmodus aktivieren
                    # Wechseln der GPIOs in der Frequenz, die durch den Wert des Blink-Schalters bestimmt wird
                    blink_interval = (1 / switch[4] * 3) + 2
                    if (datetime.datetime.now() - lastBlink).total_seconds() > blink_interval:
                        GPIO.output(outputs[i], not GPIO.input(outputs[i]))  # Wechseln des Status
                        lastBlink = datetime.datetime.now()  # Aktualisieren des letzten Blink-Zeitpunkts

            if (i == 1 or i == 2): # Farbpins sind invertiert (Pin AUS -> Farbe an
                if switch[3] == 0:
                    GPIO.output(outputs[i], GPIO.LOW)
            else:
                if switch[4] == 0:
                    GPIO.output(outputs[i], GPIO.HIGH)
        else:
            if (i == 1 or i == 2):
                if switch[3] == 0:
                    GPIO.output(outputs[i], GPIO.HIGH)
            else:
                GPIO.output(outputs[i], GPIO.LOW)  # Andernfalls setze den Ausgangspin auf niedrig
   
    # Wenn sich der Zustand der Schalter geändert hat
    if  switch != switch_old and GPIO.input(18) != GPIO.HIGH:
        blink_led(16)
        last_opc_interaction = datetime.datetime.now()

    if (datetime.datetime.now() - last_opc_interaction).total_seconds() > reset_cooldown:
        reset_led()
        print("resetting all pins!")
        last_opc_interaction = datetime.datetime.now()

    # Kopieren der aktuellen Schalterzustände in switch_old für die nächste Iteration
    switch_old = list(switch) 

    # Aktualisieren der Variablenwerte im OPC UA-Server mit den aktuellen Schalterzuständen, dem Änderungsflag und der aktuellen Zeit
    switch1.set_value(switch[0])
    switch2.set_value(switch[1])
    switch3.set_value(switch[2])
    switch4.set_value(switch[3])
    switch5.set_value(switch[4])
    timestamp.set_value(last_opc_interaction)

    time.sleep(0.5)