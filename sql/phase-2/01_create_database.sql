-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 01_create_database.sql
-- Purpose  : Create the database for the MySQL DBA project
-- ============================================================

CREATE DATABASE IF NOT EXISTS cancer_environment_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cancer_environment_db;