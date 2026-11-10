import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TaskService } from '../../../core/services/task.service';
import { UserService } from '../../../core/services/user.service';
import { DialogService } from '../../../core/services/dialog.service';
import { ChoreTask, TaskType } from '../../../core/models/task.model';
import { User } from '../../../core/models/user.model';

@Component({
  selector: 'app-admin-tasks',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './admin-tasks.component.html'
})
export class AdminTasksComponent implements OnInit {
  tasks = signal<ChoreTask[]>([]);
  children = signal<User[]>([]);
  loading = signal(true);
  showForm = signal(false);
  editingTask = signal<ChoreTask | null>(null);
  form: FormGroup;
  TaskType = TaskType;
  saving = signal(false);

  // Day options for SpecificDays
  daysList = [
    { id: '1', label: 'Senin' },
    { id: '2', label: 'Selasa' },
    { id: '3', label: 'Rabu' },
    { id: '4', label: 'Kamis' },
    { id: '5', label: 'Jumat' },
    { id: '6', label: 'Sabtu' },
    { id: '7', label: 'Minggu' }
  ];
  selectedDays = signal<string[]>([]);

  // Re-assign modal state
  showAssignModal = signal(false);
  assigningTask = signal<ChoreTask | null>(null);
  assignChildId = signal('');
  assignDueDate = signal(new Date().toISOString().substring(0, 10));
  isAssigning = signal(false);

  emojiOptions = ['🧹', '🌱', '📚', '🍽️', '🛏️', '🚾', '🗑️', '🛒', '🧺', '🧼', '🐕', '🌙', '☀️', '🍳', '🧴'];

  constructor(
    private taskService: TaskService,
    private userService: UserService,
    private fb: FormBuilder,
    private dialog: DialogService
  ) {
    this.form = this.fb.group({
      title: ['', Validators.required],
      description: [''],
      taskType: [TaskType.Daily, Validators.required],
      assignedToId: [''],
      points: [10, [Validators.required, Validators.min(1)]],
      iconEmoji: ['✅', Validators.required],
      dueDate: [new Date().toISOString().substring(0, 10)]
    });
  }

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading.set(true);
    this.taskService.getTasks(false).subscribe(tasks => {
      this.tasks.set(tasks);
      this.loading.set(false);
    });
    this.userService.getChildren().subscribe(c => this.children.set(c));
  }

  openCreate() {
    this.editingTask.set(null);
    this.selectedDays.set(['1', '3', '5']);
    this.form.reset({
      taskType: TaskType.Daily,
      points: 10,
      iconEmoji: '✅',
      dueDate: new Date().toISOString().substring(0, 10)
    });
    this.showForm.set(true);
  }

  openEdit(task: ChoreTask) {
    this.editingTask.set(task);
    if (task.daysOfWeek) {
      this.selectedDays.set(task.daysOfWeek.split(',').filter(d => !!d));
    } else {
      this.selectedDays.set(['1', '3', '5']);
    }

    this.form.patchValue({
      title: task.title,
      description: task.description,
      taskType: task.taskType,
      assignedToId: task.assignedToId || '',
      points: task.points,
      iconEmoji: task.iconEmoji,
      dueDate: new Date().toISOString().substring(0, 10)
    });
    this.showForm.set(true);
  }

  toggleDay(dayId: string) {
    const current = this.selectedDays();
    if (current.includes(dayId)) {
      this.selectedDays.set(current.filter(id => id !== dayId));
    } else {
      this.selectedDays.set([...current, dayId].sort());
    }
  }

  getScheduleLabel(task: ChoreTask): string {
    if (task.taskType === TaskType.Daily) return '🔁 Rutin Setiap Hari';
    if (task.taskType === TaskType.OneTime) return '⚡ Sekali Saja';
    if (task.taskType === TaskType.SpecificDays) {
      if (!task.daysOfWeek) return '📅 Hari Tertentu';
      const dayNames = task.daysOfWeek.split(',')
        .map(id => this.daysList.find(d => d.id === id)?.label)
        .filter(Boolean);
      return `📅 ${dayNames.join(', ')}`;
    }
    return task.taskType;
  }

  save() {
    if (this.form.invalid) return;
    this.saving.set(true);
    const formVal = this.form.value;
    const data: any = {
      title: formVal.title,
      description: formVal.description,
      taskType: formVal.taskType,
      points: formVal.points,
      iconEmoji: formVal.iconEmoji,
      dueDate: formVal.dueDate,
      assignedToId: formVal.assignedToId ? formVal.assignedToId : null
    };

    if (formVal.taskType === TaskType.SpecificDays) {
      data.daysOfWeek = this.selectedDays().join(',');
    }

    const request = this.editingTask()
      ? this.taskService.updateTask(this.editingTask()!.id, data)
      : this.taskService.createTask(data);

    request.subscribe({
      next: () => {
        this.showForm.set(false);
        this.loadData();
        this.saving.set(false);
      },
      error: () => this.saving.set(false)
    });
  }

  openAssignModal(task: ChoreTask) {
    this.assigningTask.set(task);
    this.assignChildId.set(task.assignedToId || '');
    this.assignDueDate.set(new Date().toISOString().substring(0, 10));
    this.showAssignModal.set(true);
  }

  submitAssign() {
    const task = this.assigningTask();
    if (!task) return;
    this.isAssigning.set(true);

    this.taskService.assignTask(task.id, {
      assignedToId: this.assignChildId() || undefined,
      dueDate: this.assignDueDate()
    }).subscribe({
      next: () => {
        this.isAssigning.set(false);
        this.showAssignModal.set(false);
        this.dialog.success(`Tugas '${task.title}' berhasil ditugaskan!`);
      },
      error: (err) => {
        this.isAssigning.set(false);
        this.dialog.error('Gagal menugaskan: ' + (err.error?.message || 'Error'));
      }
    });
  }

  toggleActive(task: ChoreTask) {
    this.taskService.updateTask(task.id, { isActive: !task.isActive }).subscribe(() => this.loadData());
  }

  selectEmoji(emoji: string) {
    this.form.patchValue({ iconEmoji: emoji });
  }
}
