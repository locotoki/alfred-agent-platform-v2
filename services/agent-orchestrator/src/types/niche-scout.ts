
export interface Category {
  label: string;
  value: string;
}

export interface DataSourceConfig {
  youtube: boolean;
  reddit: boolean;
  amazon: boolean;
  sentiment: boolean;
}

export interface FinalPayload {
  category: Category;
  subcategory: Category;
  budget: number;
  dataSources: DataSourceConfig;
  estimatedTime: number;
  estimatedCost: number;
}
