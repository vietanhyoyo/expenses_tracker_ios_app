ALTER TABLE `categories`
  ADD COLUMN `color_hex` CHAR(7) NOT NULL DEFAULT '#64748B';

UPDATE `categories`
SET `color_hex` = CASE `name`
  WHEN 'Ăn uống' THEN '#FF5D73'
  WHEN 'Di chuyển' THEN '#3B82F6'
  WHEN 'Mua sắm' THEN '#A855F7'
  WHEN 'Giải trí' THEN '#EC4899'
  WHEN 'Hoá đơn' THEN '#F59E0B'
  WHEN 'Tiện ích' THEN '#F59E0B'
  WHEN 'Sức khoẻ' THEN '#EF4444'
  WHEN 'Sức khỏe' THEN '#EF4444'
  WHEN 'Giáo dục' THEN '#14B8A6'
  WHEN 'Lương' THEN '#10B981'
  WHEN 'Thưởng' THEN '#F59E0B'
  WHEN 'Đầu tư' THEN '#0EA5E9'
  WHEN 'Thu nhập khác' THEN '#8B5CF6'
  ELSE `color_hex`
END
WHERE `is_default` = true;
