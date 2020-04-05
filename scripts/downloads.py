from pytg import Telegram
from pytg.utils import coroutine

tg = Telegram(telegram="/home/osmc/tgc/bin/telegram-cli", pubkey_file="/home/osmc/tgc/tg-server.pub") 
receiver = tg.receiver

@coroutine
def main_loop():
  quit = False
  try:
    while not quit:
      msg = (yield) # it waits until it got a message, stored now in msg.
      if 'text' in msg and msg.text is not None:
        print(msg.event)
        print(msg.text)
      if 'media' in msg and msg.media is not None:
        print("Msg with media")

  except GeneratorExit:
    pass
  except KeyboardInterrupt:
    quit = True
    pass
  else:
    pass
receiver.start()
receiver.message(main_loop())
