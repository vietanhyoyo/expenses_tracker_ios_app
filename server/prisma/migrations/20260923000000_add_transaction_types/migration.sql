ALTER TABLE `categories`
  ADD COLUMN `type` ENUM('income', 'expense') NOT NULL DEFAULT 'expense';

ALTER TABLE `expenses`
  ADD COLUMN `type` ENUM('income', 'expense') NOT NULL DEFAULT 'expense';

CREATE UNIQUE INDEX `categories_user_id_normalized_name_type_key`
  ON `categories`(`user_id`, `normalized_name`, `type`);

DROP INDEX `categories_user_id_normalized_name_key` ON `categories`;

CREATE INDEX `expenses_user_id_type_expense_date_idx`
  ON `expenses`(`user_id`, `type`, `expense_date`);
