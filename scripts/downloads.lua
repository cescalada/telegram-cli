local allowed_users_id = {1127263631}
local command = 'Download'
local destination_dir = '/media/usb2/torrents'
local smtp = require("socket.smtp")
local ltn12 = require("ltn12")
local mime = require("mime")
local ssl = require("ssl")
local socket= require('socket')

local SMTP_SERVER = "smtp.free.fr"
local SMTP_AUTH_USER = ""
local SMTP_AUTH_PW = ""
local SMTP_PORT = 465
local FROM = ""
local TO = ""

---------------------------------------------------

started = 0
our_id = 0

print ("HI, this is lua script")

function ok_cb(data, success, result)
   print('Download: file: '..result..' - ok: '..success..' - extra: '..data[0]..' - type: '..data[2])
   if success then
      if data[2] == 'movie' then
         os.move(result, destination_dir..'/'..data[0])
      end
      if data[2] == 'news' and data[1] < (24*1024*1024) then
	 --print('send mail!!!!!')
	 send_email_attachment(result, data[0], 'application/pdf')
	 os.remove(result)
      else
	 print('news too big!!!!!')
      end
   end
end


command_before = ''
function on_msg_receive (msg)
  if started == 0 then
    return
  end
  if msg.out then
    return
  end

 --  print('Id de ' ..msg.from.print_name.. ' : '..msg.from.peer_id)

  for _,v in pairs(allowed_users_id) do
     if v == msg.from.peer_id then

	if msg.text then
	
	    if string.find(msg.text, "magnet") then
	       os.execute('transmission-cli '..msg.text)
	    end
	end
	   
	if msg.media then

           mark_read (msg.from.id, cb_ok, true)

           -- print('Type: ' ..msg.media.type)

	   if msg.media.type == 'document' then
	      data = {}
	      data[0] = msg.media.caption
	      data[1] = msg.media.size

              if msg.media.size > (100*1024*1024) then
	        data[2] = 'movie'
	      else
	        data[2] = 'news'
	      end

	      --print('Caption: '..msg.media.caption..' - Size: '..msg.media.size)
	      load_document(msg.id, ok_cb, data)
	   end
--	   if msg.media.type == 'photo' then
--	      load_photo(msg.id, ok_cb, msg.id)
--	   end
--	   if msg.media.type == 'video' then
--	      load_video(msg.id, ok_cb, msg.id)
--	   end
--	   if msg.media.type == 'audio' then
--	      load_audio(msg.id, ok_cb, msg.id)
--	   end
	end

        break

     end
     commad_before = msg.text
  end


end

function on_our_id (id)
  our_id = id
end


function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

function cron()
  -- do something
  postpone (cron, false, 1.0)
end

function on_binlog_replay_end ()
  started = 1
  postpone (cron, false, 1.0)
end

function sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            local r, e = sock:connect(host, port)
            if not r then return r, e end
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            return sock:dohandshake()
        end
    }, {
        __index = function(t,n)
            return function(_, ...)
                return sock[n](sock, ...)
            end
        end
    })
end



function send_email_attachment(file_path, filename, content_type)

   rcpt = {
      TO
   }

   msgt = {
      headers = {
         to = TO,
	 subject = "[kiosko] "..filename,
	 from = FROM
      },
      body = {
         -- the message content
	 [1] = {
	     body = "File for you"
	 },
	 -- the file attachmemt
	 [2] = {
	     headers = {
	        ["content-type"] = content_type..'; name="'..filename..'"',
	        ["content-disposition"] = 'attachment; filename="'..filename..'"',
	        ["content-description"] = '',
	        ["content-transfer-encoding"] = "BASE64",
	     },
	     body = ltn12.source.chain(
	             ltn12.source.file( io.open(file_path, "rb")),
		     ltn12.filter.chain(
		        mime.encode("base64"),
			mime.wrap()
		     )
	     )
	 }
      }
   }

   local r, e = smtp.send{
      from = FROM,
      rcpt = rcpt,
      source = smtp.message(msgt),
      server = SMTP_SERVER,
      port = SMTP_PORT,
      user = SMTP_AUTH_USER,
      password = SMTP_AUTH_PW,
      create = sslCreate
   }

   if r ~= 1 then
      print('ERROR sending mail. '..e)
   end

end


