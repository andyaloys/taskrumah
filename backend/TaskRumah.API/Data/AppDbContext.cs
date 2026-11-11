using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Models;

namespace TaskRumah.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<ChoreTask> ChoreTasks => Set<ChoreTask>();
    public DbSet<TaskAssignment> TaskAssignments => Set<TaskAssignment>();
    public DbSet<TaskComment> TaskComments => Set<TaskComment>();
    public DbSet<Reward> Rewards => Set<Reward>();
    public DbSet<RewardRedemption> RewardRedemptions => Set<RewardRedemption>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<WorshipSetting> WorshipSettings => Set<WorshipSetting>();
    public DbSet<DailyWorship> DailyWorships => Set<DailyWorship>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ChoreTask>(entity =>
        {
            entity.HasOne(t => t.AssignedTo)
                  .WithMany(u => u.AssignedTasks)
                  .HasForeignKey(t => t.AssignedToId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(t => t.CreatedBy)
                  .WithMany(u => u.CreatedTasks)
                  .HasForeignKey(t => t.CreatedById)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TaskAssignment>(entity =>
        {
            entity.HasOne(a => a.Task)
                  .WithMany(t => t.Assignments)
                  .HasForeignKey(a => a.TaskId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.AssignedTo)
                  .WithMany(u => u.TaskAssignments)
                  .HasForeignKey(a => a.AssignedToId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(a => a.ReviewedBy)
                  .WithMany()
                  .HasForeignKey(a => a.ReviewedById)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<TaskComment>(entity =>
        {
            entity.HasOne(c => c.TaskAssignment)
                  .WithMany(a => a.Comments)
                  .HasForeignKey(c => c.TaskAssignmentId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(c => c.User)
                  .WithMany()
                  .HasForeignKey(c => c.UserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Reward>(entity =>
        {
            entity.HasOne(r => r.CreatedBy)
                  .WithMany()
                  .HasForeignKey(r => r.CreatedById)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<RewardRedemption>(entity =>
        {
            entity.HasOne(r => r.Reward)
                  .WithMany(r => r.Redemptions)
                  .HasForeignKey(r => r.RewardId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.User)
                  .WithMany(u => u.RewardRedemptions)
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.ProcessedBy)
                  .WithMany()
                  .HasForeignKey(r => r.ProcessedById)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasOne(n => n.User)
                  .WithMany(u => u.Notifications)
                  .HasForeignKey(n => n.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DailyWorship>(entity =>
        {
            entity.HasIndex(w => new { w.UserId, w.Date }).IsUnique();
            entity.HasOne(w => w.User)
                  .WithMany()
                  .HasForeignKey(w => w.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<WorshipSetting>().HasData(
            new WorshipSetting
            {
                Id = Guid.Parse("99999999-9999-9999-9999-999999999999"),
                SoloPoints = 3,
                MosquePoints = 5,
                QuranPoints = 5,
                UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        SeedData(modelBuilder);
    }

    private static void SeedData(ModelBuilder modelBuilder)
    {
        var ayahId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var ibuId = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var anak1Id = Guid.Parse("33333333-3333-3333-3333-333333333333");
        var anak2Id = Guid.Parse("44444444-4444-4444-4444-444444444444");

        modelBuilder.Entity<User>().HasData(
            new User
            {
                Id = ayahId,
                Name = "Papah",
                Email = "ayah@taskrumah.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Ayah@123"),
                Role = UserRole.Admin,
                TotalPoints = 0,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastStreakDate = DateTime.UtcNow.Date,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                IsActive = true
            },
            new User
            {
                Id = ibuId,
                Name = "Mamah",
                Email = "ibu@taskrumah.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Ibu@123"),
                Role = UserRole.Admin,
                TotalPoints = 0,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastStreakDate = DateTime.UtcNow.Date,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                IsActive = true
            },
            new User
            {
                Id = anak1Id,
                Name = "Anak Pertama",
                Email = "anak1@taskrumah.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Anak1@123"),
                Role = UserRole.Child,
                TotalPoints = 0,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastStreakDate = DateTime.UtcNow.Date,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                IsActive = true
            },
            new User
            {
                Id = anak2Id,
                Name = "Anak Kedua",
                Email = "anak2@taskrumah.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Anak2@123"),
                Role = UserRole.Child,
                TotalPoints = 0,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastStreakDate = DateTime.UtcNow.Date,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                IsActive = true
            }
        );

        modelBuilder.Entity<ChoreTask>().HasData(
            new ChoreTask
            {
                Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                Title = "Bersihkan Kamar Mandi",
                Description = "Sikat toilet, lap wastafel, dan pel lantai kamar mandi",
                TaskType = TaskType.Daily,
                AssignedToId = anak1Id,
                CreatedById = ayahId,
                Points = 20,
                IconEmoji = "🚽",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChoreTask
            {
                Id = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                Title = "Siram Tanaman",
                Description = "Siram semua tanaman di halaman dan balkon",
                TaskType = TaskType.Daily,
                AssignedToId = anak2Id,
                CreatedById = ayahId,
                Points = 10,
                IconEmoji = "🌱",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChoreTask
            {
                Id = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                Title = "Belajar",
                Description = "Belajar minimal 1 jam setiap hari",
                TaskType = TaskType.Daily,
                AssignedToId = null,
                CreatedById = ibuId,
                Points = 15,
                IconEmoji = "📚",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChoreTask
            {
                Id = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                Title = "Cuci Piring",
                Description = "Cuci semua piring kotor setelah makan",
                TaskType = TaskType.Daily,
                AssignedToId = anak1Id,
                CreatedById = ibuId,
                Points = 10,
                IconEmoji = "🍽️",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChoreTask
            {
                Id = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
                Title = "Rapikan Kamar",
                Description = "Rapikan tempat tidur dan bereskan mainan atau pakaian",
                TaskType = TaskType.Daily,
                AssignedToId = anak2Id,
                CreatedById = ibuId,
                Points = 10,
                IconEmoji = "🛏️",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        modelBuilder.Entity<Reward>().HasData(
            new Reward
            {
                Id = Guid.Parse("f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1"),
                Title = "Es Krim Favorit",
                Description = "Es krim rasa favorit pilihan kamu",
                PointsRequired = 50,
                IconEmoji = "🍦",
                CreatedById = ayahId,
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Reward
            {
                Id = Guid.Parse("f2f2f2f2-f2f2-f2f2-f2f2-f2f2f2f2f2f2"),
                Title = "Main Game 1 Jam Ekstra",
                Description = "Dapat waktu main game tambahan 1 jam",
                PointsRequired = 30,
                IconEmoji = "🎮",
                CreatedById = ayahId,
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Reward
            {
                Id = Guid.Parse("f3f3f3f3-f3f3-f3f3-f3f3-f3f3f3f3f3f3"),
                Title = "Nonton Bioskop",
                Description = "Pergi nonton film di bioskop bersama keluarga",
                PointsRequired = 100,
                IconEmoji = "🎬",
                CreatedById = ibuId,
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );
    }
}
