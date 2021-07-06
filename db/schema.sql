--
-- PostgreSQL database dump
--

-- Dumped from database version 10.15 (Ubuntu 10.15-1.pgdg16.04+1)
-- Dumped by pg_dump version 13.2 (Ubuntu 13.2-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: message_target; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_target AS ENUM (
    'user',
    'app',
    'email',
    'dashboard'
);


SET default_tablespace = '';

--
-- Name: followups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.followups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    body text NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    producer_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    target_type public.message_target NOT NULL,
    target_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    action_label text,
    action_url text
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    user_id uuid,
    message_id uuid NOT NULL,
    read_at timestamp with time zone,
    recipient_id uuid
);

CREATE TABLE public.team_notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    message_id uuid NOT NULL,
    email text NOT NULL
);

CREATE TABLE public.available_team_notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    team_manager_email text NOT NULL,
    team_notification_email text NOT NULL
);

--
-- Name: producers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    encrypted_api_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);


--
-- Name: recipients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_id uuid NOT NULL,
    email text NOT NULL,
    verification_token character(5) NOT NULL,
    verification_sent_at timestamp with time zone DEFAULT now() NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    filename text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    heroku_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    email text NOT NULL
);


--
-- Name: followups followups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followups
    ADD CONSTRAINT followups_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: producers producers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producers
    ADD CONSTRAINT producers_pkey PRIMARY KEY (id);


--
-- Name: recipients recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipients
    ADD CONSTRAINT recipients_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: users users_heroku_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_heroku_id_key UNIQUE (heroku_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: followups_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX followups_message_id_index ON public.followups USING btree (message_id);


--
-- Name: messages_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_created_at_index ON public.messages USING btree (created_at);


--
-- Name: messages_producer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_producer_id_index ON public.messages USING btree (producer_id);


--
-- Name: messages_target_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_target_id_index ON public.messages USING btree (target_id);


--
-- Name: notifications_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_message_id_index ON public.notifications USING btree (message_id);


--
-- Name: notifications_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_id_index ON public.notifications USING btree (user_id);


--
-- Name: notifications_user_id_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX notifications_user_id_message_id_index ON public.notifications USING btree (user_id, message_id);


--
-- Name: notifications_user_id_null_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_id_null_read_at ON public.notifications USING btree (user_id) WHERE (read_at IS NULL);


--
-- Name: recipients_app_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX recipients_app_id_email_index ON public.recipients USING btree (app_id, email) WHERE (deleted_at IS NULL);


--
-- Name: recipients_app_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipients_app_id_index ON public.recipients USING btree (app_id);


--
-- Name: users_heroku_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_heroku_id_index ON public.users USING btree (heroku_id);


--
-- Name: followups followups_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followups
    ADD CONSTRAINT followups_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: messages messages_producer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);


--
-- Name: messages messages_producer_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_producer_id_fkey1 FOREIGN KEY (producer_id) REFERENCES public.producers(id);


--
-- Name: notifications notifications_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: notifications notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.recipients(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications notifications_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_notifications
    ADD CONSTRAINT team_notifications_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);

--
-- PostgreSQL database dump complete
--

SET search_path = "$user", public;

INSERT INTO "schema_migrations" ("filename") VALUES ('1407447674_create_producers.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1408052086_create_messages.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1409180490_create_users.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1409788381_create_notifications.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1413499263_create_followups.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1413499264_add_indexes.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1415147638_notification-add-read-at.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1415930380_add-constraints.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1422056536_add_action_to_messages.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1467321156_create_recipients.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1467325367_add-recipients-to-notifications.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1467356858_add_email_to_message_type.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1543529321_add_dashboard_to_message_type.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1566411434293_notifications_read_at_null_index.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1615300867_add_created_at_index.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1624557045_create_team_notifications.rb');
INSERT INTO "schema_migrations" ("filename") VALUES ('1625144842_create_available_team_notifications.rb');
