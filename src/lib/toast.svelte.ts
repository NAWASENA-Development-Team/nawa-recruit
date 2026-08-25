export type ToastType = 'success' | 'error' | 'info';

export interface ToastMessage {
  id: number;
  message: string;
  type: ToastType;
}

// Svelte 5 global state
let toasts = $state<ToastMessage[]>([]);
let nextId = 0;

export const toastStore = {
  get toasts() {
    return toasts;
  },
  
  add(message: string, type: ToastType = 'info') {
    const id = nextId++;
    toasts.push({ id, message, type });
    
    // Auto remove after 3.5 seconds
    setTimeout(() => {
      this.remove(id);
    }, 3500);
  },
  
  remove(id: number) {
    toasts = toasts.filter(t => t.id !== id);
  },
  
  success(message: string) {
    this.add(message, 'success');
  },
  
  error(message: string) {
    this.add(message, 'error');
  },
  
  info(message: string) {
    this.add(message, 'info');
  }
};
