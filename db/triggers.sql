
CREATE OR REPLACE FUNCTION notify_message_posted() RETURNS trigger AS $$
DECLARE
BEGIN
  PERFORM pg_notify('messages', 'message posted to channel ' || CAST(NEW.channel_id AS text));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_message_posted ON messages;
CREATE TRIGGER notify_message_posted  AFTER INSERT ON messages FOR EACH ROW EXECUTE PROCEDURE notify_message_posted();
