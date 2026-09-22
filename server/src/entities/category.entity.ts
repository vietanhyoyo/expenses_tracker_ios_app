export interface CategoryEntity {
  id: number;
  name: string;
  isDefault: boolean;
  userId: number | null;
  createdAt: Date;
  updatedAt: Date;
}
