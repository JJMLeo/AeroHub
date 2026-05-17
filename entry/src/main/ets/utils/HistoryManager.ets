// 历史记录管理器 - 全局管理所有页面的历史记录
import { HistoryItem } from './GasProperties';

export class HistoryManager {
  private static instance: HistoryManager;
  
  // 三个页面的历史记录
  private aerodynamicsHistory: HistoryItem[] = [];
  private standardAtmosphereHistory: HistoryItem[] = [];
  private thermodynamicPropertiesHistory: HistoryItem[] = [];
  
  // 三个页面的上次输入快照（用于去重）
  private aerodynamicsSnapshot: string = '';
  private standardAtmosphereSnapshot: string = '';
  private thermodynamicPropertiesSnapshot: string = '';
  
  private constructor() {
    // 私有构造函数，防止外部实例化
  }
  
  // 获取单例实例
  public static getInstance(): HistoryManager {
    if (!HistoryManager.instance) {
      HistoryManager.instance = new HistoryManager();
    }
    return HistoryManager.instance;
  }
  
  // 清空所有历史记录（应用启动时调用）
  public clearAllHistory(): void {
    this.aerodynamicsHistory = [];
    this.standardAtmosphereHistory = [];
    this.thermodynamicPropertiesHistory = [];
    this.aerodynamicsSnapshot = '';
    this.standardAtmosphereSnapshot = '';
    this.thermodynamicPropertiesSnapshot = '';
    console.info('[HistoryManager] All history cleared');
  }
  
  // 添加历史记录
  public addHistory(pageName: string, entry: HistoryItem, snapshot: string): void {
    switch (pageName) {
      case 'Aerodynamics':
        if (snapshot !== this.aerodynamicsSnapshot) {
          this.aerodynamicsHistory = [entry, ...this.aerodynamicsHistory].slice(0, 20);
          this.aerodynamicsSnapshot = snapshot;
        }
        break;
      case 'StandardAtmosphere':
        if (snapshot !== this.standardAtmosphereSnapshot) {
          this.standardAtmosphereHistory = [entry, ...this.standardAtmosphereHistory].slice(0, 20);
          this.standardAtmosphereSnapshot = snapshot;
        }
        break;
      case 'ThermodynamicProperties':
        if (snapshot !== this.thermodynamicPropertiesSnapshot) {
          this.thermodynamicPropertiesHistory = [entry, ...this.thermodynamicPropertiesHistory].slice(0, 20);
          this.thermodynamicPropertiesSnapshot = snapshot;
        }
        break;
    }
  }
  
  // 获取历史记录
  public getHistory(pageName: string): HistoryItem[] {
    switch (pageName) {
      case 'Aerodynamics':
        return this.aerodynamicsHistory;
      case 'StandardAtmosphere':
        return this.standardAtmosphereHistory;
      case 'ThermodynamicProperties':
        return this.thermodynamicPropertiesHistory;
      default:
        return [];
    }
  }
}
