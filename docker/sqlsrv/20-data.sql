INSERT INTO phober_auth.dbo.permissions (name, created_at, updated_at) VALUES (N'access_to_adminpanel', N'2024-12-14 17:23:55.413', N'2024-12-14 17:23:55.413');
INSERT INTO phober_auth.dbo.permissions (name, created_at, updated_at) VALUES (N'manage_sessions', N'2024-12-14 17:23:55.460', N'2024-12-14 17:23:55.460');

INSERT INTO phober_auth.dbo.roles (name, created_at, updated_at) VALUES (N'Admin', N'2024-12-14 17:23:55.463', N'2024-12-14 17:23:55.463');
INSERT INTO phober_auth.dbo.roles (name, created_at, updated_at) VALUES (N'Manager', N'2024-12-14 17:23:55.483', N'2024-12-14 17:23:55.483');
INSERT INTO phober_auth.dbo.roles (name, created_at, updated_at) VALUES (N'Cashier', N'2024-12-14 17:23:55.490', N'2024-12-14 17:23:55.490');
INSERT INTO phober_auth.dbo.roles (name, created_at, updated_at) VALUES (N'Staff', N'2024-12-14 17:23:55.497', N'2024-12-14 17:23:55.497');

INSERT INTO phober_auth.dbo.users (username, first_name, last_name, telegram, telegram_chat_id, api_token, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES (N'admin', N'Hikmat', N'Abdukhaligov', N'abdukhaligov', N'606872411', null, N'admin@site.com', null, N'$2y$12$kuz9spUnMiq2XFVReJKPWuT.3a2b4Gaw4Al8O/33nhQNMnDkpQC5q', null, N'2024-10-12 02:19:57.620', N'2025-02-09 19:48:16.710');
INSERT INTO phober_auth.dbo.users (username, first_name, last_name, api_token, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES (N'admim', N'Narmin', N'Aliyeva', null, N'manager@site.com', null, N'$2y$10$nVHcO/uSIBkb.EMiQCcs7OPikyKtjLmLWzWn1FESF7hFDjpM60F8y', null, N'2024-10-12 02:19:57.653', N'2024-12-14 17:35:37.000');
INSERT INTO phober_auth.dbo.users (username, first_name, last_name, api_token, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES (N'cashier', N'Rafael', N'Bagirov', null, N'cashier@site.com', null, N'$2y$10$nVHcO/uSIBkb.EMiQCcs7OPikyKtjLmLWzWn1FESF7hFDjpM60F8y', null, N'2024-10-12 02:19:57.657', N'2024-12-14 17:30:12.000');
INSERT INTO phober_auth.dbo.users (username, first_name, last_name, api_token, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES (N'member', N'Turkan', N'Guluzade', null, N'member@site.com', null, N'$2y$10$nVHcO/uSIBkb.EMiQCcs7OPikyKtjLmLWzWn1FESF7hFDjpM60F8y', N'4dt4NWgN7HO7ryHm1CGzkGMZbCcb3wAyrEYPHKxW7gN4JKH0oOFkzFEAKIq7', N'2024-10-12 02:19:57.663', N'2024-10-12 02:19:57.663');

INSERT INTO phober_auth.dbo.user_permissions (user_id, permission_id) VALUES (3, 1);
INSERT INTO phober_auth.dbo.user_permissions (user_id, permission_id) VALUES (3, 2);

INSERT INTO phober_auth.dbo.user_roles (user_id, role_id) VALUES (1, 1);
INSERT INTO phober_auth.dbo.user_roles (user_id, role_id) VALUES (3, 2);
INSERT INTO phober_auth.dbo.user_roles (user_id, role_id) VALUES (3, 3);
INSERT INTO phober_auth.dbo.user_roles (user_id, role_id) VALUES (3, 4);

INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (1, 1);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (1, 2);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (2, 1);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (2, 2);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (3, 2);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (4, 2);
INSERT INTO phober_auth.dbo.role_permissions (role_id, permission_id) VALUES (4, 1);

SET IDENTITY_INSERT phober_staff.dbo.employees ON;
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (1, N'Precious', N'Balistreri', N'2024-10-12 02:19:58.343', N'2024-10-12 02:19:58.343');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (2, N'Dayana', N'Smitham', N'2024-10-12 02:19:58.347', N'2024-10-12 02:19:58.347');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (3, N'Jeffery', N'Simonis', N'2024-10-12 02:19:58.350', N'2024-10-12 02:19:58.350');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (4, N'Daryl', N'Lang', N'2024-10-12 02:19:58.353', N'2024-10-12 02:19:58.353');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (5, N'Ona', N'Schimmel', N'2024-10-12 02:19:58.353', N'2024-10-12 02:19:58.353');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (6, N'sfd', N'sfd', N'2024-10-12 02:46:13.760', N'2024-10-12 02:46:13.760');
INSERT INTO phober_staff.dbo.employees (id, first_name, last_name, created_at, updated_at) VALUES (7, N'dd', N'ff', N'2024-12-01 13:32:53.057', N'2024-12-01 13:32:53.057');
SET IDENTITY_INSERT phober_staff.dbo.employees OFF;

SET IDENTITY_INSERT phober_staff.dbo.snacks ON;
INSERT INTO phober_staff.dbo.snacks (id, name, stock, price, created_at, updated_at) VALUES (1, N'Red Bull', 15, 2.5, N'2024-10-12 02:19:58.357', N'2024-10-12 02:19:58.357');
INSERT INTO phober_staff.dbo.snacks (id, name, stock, price, created_at, updated_at) VALUES (2, N'Coca-Cola', 6, 2, N'2024-10-12 02:19:58.363', N'2024-10-12 02:19:58.363');
INSERT INTO phober_staff.dbo.snacks (id, name, stock, price, created_at, updated_at) VALUES (3, N'Fanta', 1, 2, N'2024-10-12 02:19:58.367', N'2024-10-12 02:19:58.367');
INSERT INTO phober_staff.dbo.snacks (id, name, stock, price, created_at, updated_at) VALUES (4, N'Snickers', 15, 1.5, N'2024-10-12 02:19:58.367', N'2024-10-12 02:19:58.367');
SET IDENTITY_INSERT phober_staff.dbo.snacks OFF;
