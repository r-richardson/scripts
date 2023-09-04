#!/usr/bin/python3
import math
import random
import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO
import time
import datetime
import threading

# Set the username and password for MQTT
USERNAME = 'USERNAME_HERE'; PASSWORD = 'PASSWORD_HERE'
reset_cooldown = 600

# Set the GPIO pins for the LEDs
success_pin = 16
failure_pin = 18

power_pin = 35
red_pin = 33
green_pin = 37

pins = [success_pin, failure_pin, power_pin, red_pin, green_pin]

GPIO.setmode(GPIO.BOARD)
for pin in pins:
    GPIO.setup(pin, GPIO.OUT)

def set_led(power_state = None, red_state = None, green_state = None):

    if power_state == None:
        if GPIO.input(power_pin) == GPIO.HIGH:
            power_state = True
        else:
            power_state = False
    
    if red_state == None:
        if GPIO.input(red_pin) == GPIO.LOW:
            red_state = True
        else:
            red_state = False

    if green_state == None:
        if GPIO.input(green_pin) == GPIO.LOW:
            green_state = True
        else:
            green_state = False

    if power_state:
        GPIO.output(power_pin, GPIO.HIGH)
    else:
        GPIO.output(power_pin, GPIO.LOW)

    if red_state:
        GPIO.output(red_pin, GPIO.LOW)
    else:
        GPIO.output(red_pin, GPIO.HIGH)
    
    if green_state:
        GPIO.output(green_pin, GPIO.LOW)
    else:
        GPIO.output(green_pin, GPIO.HIGH)

def status_blink(pin, amount = 1, interval = 3):
    while amount > 0:
        GPIO.output(pin, GPIO.HIGH)
        time.sleep(interval)
        GPIO.output(pin, GPIO.LOW)
        time.sleep(interval)
        amount -= 1

error_happened = False
def error_case():
    global error_happened
    error_happened = True
    status_blink(failure_pin)

blink_thread = None  # Global variable to store the blink thread
blink_interval = 5
last_blink_time = datetime.datetime.now()
blink_thread_flag = False  # Flag to control the thread execution

def blink_led(led_pin, amount = 1):
    global last_blink_time, blink_thread_flag
    while amount > 0 or blink_thread_flag:
        if (datetime.datetime.now() - last_blink_time).total_seconds() > blink_interval:
            if GPIO.input(led_pin) == GPIO.LOW:
                GPIO.output(led_pin, GPIO.HIGH)
            else:
                GPIO.output(led_pin, GPIO.LOW)
            last_blink_time = datetime.datetime.now()
            if not blink_thread_flag:
                amount -= 1

def start_blink_thread():
    global blink_thread, blink_thread_flag
    if GPIO.input(power_pin) == GPIO.HIGH:
        blink_thread_flag = True
        blink_thread = threading.Thread(target=blink_led, args=(power_pin,))
        blink_thread.start()
    else:
        error_case()
        
def stop_blink_thread():
    global blink_thread, blink_thread_flag
    blink_thread_flag = False
    if blink_thread and blink_thread.is_alive():
        blink_thread.join()
        blink_thread = None

disko_thread = None
last_disko_time = datetime.datetime.now()
disko_thread_flag = False

def disko_mode(disko_interval = 1):
    global last_disko_time, disko_thread_flag
    color = newcolor = 4
    while disko_thread_flag:
        if (datetime.datetime.now() - last_disko_time).total_seconds() > disko_interval:
            last_disko_time = datetime.datetime.now()
            while color == newcolor:
                newcolor = random.randint(1,4)
            color = newcolor
            if color == 1: set_led(red_state=False, green_state=False)
            elif color == 2: set_led(red_state=True, green_state=False)
            elif color == 3: set_led(red_state=False, green_state=True)
            elif color == 4: set_led(red_state=True, green_state=True)

def start_disko_thread():
    global disko_thread, disko_thread_flag
    if GPIO.input(power_pin) == GPIO.LOW:
        set_led(True)
    disko_thread_flag = True
    disko_thread = threading.Thread(target=disko_mode)
    disko_thread.start()
        
def stop_disko_thread():
    global disko_thread, disko_thread_flag
    disko_thread_flag = False
    if disko_thread and disko_thread.is_alive():
        disko_thread.join()
        disko_thread = None

def is_valid_number(value, min = 1, max = 3):
    try:
        if int(value) in range(min, max + 1):
            return True
        return False
    except ValueError:
        return False
    
def is_turn_on_request(request):
    # if request == 'an' or request == 'anschalten' or request == 'on' or request == '1':
    if request == 'an':
        return True
    return False

def is_turn_off_request(request):
    # if request == 'aus' or request == 'ausschalten' or request == 'off' or request == '0':
    if request == 'aus':
        return True
    return False

last_state = [GPIO.input(power_pin), GPIO.input(red_pin), GPIO.input(green_pin), blink_thread_flag, blink_interval, disko_thread_flag]
last_mqtt_interaction = datetime.datetime.now()

def reset_led():
    stop_blink_thread()
    stop_disko_thread()
    global blink_interval; blink_interval = 5
    set_led(False, False, False)
reset_led()

def reset_led_thread():
    while True:
        if (datetime.datetime.now() - last_mqtt_interaction).total_seconds() > reset_cooldown:
            reset_led()
reset_led_thread = threading.Thread(target=reset_led_thread)
reset_led_thread.start()

# Function to be called when a connection is established
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))
    client.subscribe("#")

# Function to be called when a message is received
def on_message(client, userdata, msg):
    global error_happened; error_happened = False
    request = msg.payload.decode()
    topic = msg.topic

    if mqtt.topic_matches_sub(topic, "led"):
        if is_turn_on_request(request) and GPIO.input(power_pin) == GPIO.LOW:
            set_led(power_state = True)
        elif is_turn_off_request(request) and GPIO.input(power_pin) == GPIO.HIGH:
            set_led(power_state = False)
        elif request == 'reset' or request == 'zurücksetzen' or request == 'r':
            reset_led()
        else:
            error_case()

    elif mqtt.topic_matches_sub(topic, "led/blinken"):
        global blink_thread_flag
        global blink_interval
        if is_turn_on_request(request) and not blink_thread_flag:
            set_led(power_state = True)
            start_blink_thread()
        elif is_turn_off_request(request) and blink_thread_flag:
            stop_blink_thread()
        else:
            error_case()
    
    elif mqtt.topic_matches_sub(topic, "led/blinken/geschwindigkeit"):
        if is_valid_number(request):
            blink_interval = (1 / int(request) * 3) + 2
        else:
            error_case()

    elif mqtt.topic_matches_sub(topic, "led/farbe/rot"):
        if is_turn_on_request(request) and GPIO.input(red_pin) == GPIO.HIGH:
            set_led(power_state=True, red_state = True)
        elif is_turn_off_request(request) and GPIO.input(red_pin) == GPIO.LOW:
            set_led(green_state = False)
        else:
            error_case()

    elif mqtt.topic_matches_sub(topic, "led/farbe/grün"):
        if is_turn_on_request(request) and GPIO.input(green_pin) == GPIO.HIGH:
            set_led(power_state=True, green_state = True)
        elif is_turn_off_request(request) and GPIO.input(green_pin) == GPIO.LOW:
            set_led(green_state = False)
        else:
            error_case()

    elif mqtt.topic_matches_sub(topic, "led/farbe/disko"):
        global disko_thread_flag
        if is_turn_on_request(request) and not disko_thread_flag:
            start_disko_thread()
        elif is_turn_off_request(request) and disko_thread_flag:
            stop_disko_thread()
        else:
            error_case()
    else:
        error_case()    

    global last_mqtt_interaction; last_mqtt_interaction = datetime.datetime.now()
    new_state = [GPIO.input(power_pin), GPIO.input(red_pin), GPIO.input(green_pin), blink_thread_flag, blink_interval, disko_thread_flag]

    global last_state
    if last_state != new_state and not error_happened:
        status_blink(success_pin)
        last_state = new_state

client = mqtt.Client()
client.username_pw_set(USERNAME, PASSWORD)
client.on_connect = on_connect
client.on_message = on_message
client.connect("localhost", 1883, 60)
client.loop_forever()