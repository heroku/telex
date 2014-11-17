--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--



SET search_path = public, pg_catalog;

--
-- Name: message_target; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE message_target AS ENUM (
    'user',
    'app'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: followups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE followups (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    body text NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    producer_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    target_type message_target NOT NULL,
    target_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    user_id uuid NOT NULL,
    message_id uuid NOT NULL,
    read_at timestamp with time zone
);


--
-- Name: producers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE producers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    encrypted_api_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    filename text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    heroku_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    email text NOT NULL
);


--
-- Name: followups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY followups
    ADD CONSTRAINT followups_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: producers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY producers
    ADD CONSTRAINT producers_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: users_heroku_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_heroku_id_key UNIQUE (heroku_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: followups_message_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX followups_message_id_index ON followups USING btree (message_id);


--
-- Name: messages_producer_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_producer_id_index ON messages USING btree (producer_id);


--
-- Name: messages_target_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_target_id_index ON messages USING btree (target_id);


--
-- Name: notifications_message_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX notifications_message_id_index ON notifications USING btree (message_id);


--
-- Name: notifications_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX notifications_user_id_index ON notifications USING btree (user_id);


--
-- Name: notifications_user_id_message_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX notifications_user_id_message_id_index ON notifications USING btree (user_id, message_id);


--
-- Name: users_heroku_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_heroku_id_index ON users USING btree (heroku_id);


--
-- Name: followups_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY followups
    ADD CONSTRAINT followups_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(id);


--
-- Name: messages_producer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES producers(id);


--
-- Name: messages_producer_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_producer_id_fkey1 FOREIGN KEY (producer_id) REFERENCES producers(id);


--
-- Name: notifications_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(id);


--
-- Name: notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" ("filename") VALUES ('1407447674_create_producers.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1408052086_create_messages.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1409180490_create_users.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1409788381_create_notifications.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1413499263_create_followups.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1413499264_add_indexes.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1415147638_notification-add-read-at.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1415930380_add-constraints.rb');
