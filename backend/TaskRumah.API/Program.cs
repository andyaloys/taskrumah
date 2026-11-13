using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text.Json.Serialization;
using TaskRumah.API.Data;
using TaskRumah.API.Services;

AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaskRumah API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddScoped<JwtService>();
builder.Services.AddScoped<FileStorageService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<TaskScheduleService>();
builder.Services.AddHostedService<DailyTaskGeneratorService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAngular");
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Apply migrations and seed data
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    db.Database.ExecuteSqlRaw("ALTER TABLE \"ChoreTasks\" ADD COLUMN IF NOT EXISTS \"DaysOfWeek\" text;");

    // Configure database timezone to Asia/Jakarta (WIB)
    try
    {
        db.Database.ExecuteSqlRaw("ALTER DATABASE taskrumah SET timezone TO 'Asia/Jakarta';");
        db.Database.ExecuteSqlRaw("ALTER ROLE taskrumah_user SET timezone TO 'Asia/Jakarta';");
        db.Database.ExecuteSqlRaw("SET TIME ZONE 'Asia/Jakarta';");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Timezone config note: {ex.Message}");
    }

    // Ensure clean Jakarta local timestamps without time zone (+07) offsets
    try
    {
        db.Database.ExecuteSqlRaw(@"
            DO $$
            BEGIN
                ALTER TABLE ""TaskAssignments"" ALTER COLUMN ""DueDate"" TYPE timestamp without time zone;
                ALTER TABLE ""TaskAssignments"" ALTER COLUMN ""CreatedAt"" TYPE timestamp without time zone;
                ALTER TABLE ""TaskAssignments"" ALTER COLUMN ""CompletedAt"" TYPE timestamp without time zone;
                ALTER TABLE ""TaskAssignments"" ALTER COLUMN ""ReviewedAt"" TYPE timestamp without time zone;
                ALTER TABLE ""Users"" ALTER COLUMN ""LastStreakDate"" TYPE timestamp without time zone;
                ALTER TABLE ""Users"" ALTER COLUMN ""CreatedAt"" TYPE timestamp without time zone;
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END $$;

            -- Restore tasks completed today (13 Nov) that were accidentally shifted
            UPDATE ""TaskAssignments""
            SET ""DueDate"" = '2026-11-13 23:59:59'
            WHERE (""CompletedAt"" >= '2026-11-13 00:00:00' OR ""ReviewedAt"" >= '2026-11-13 00:00:00' OR (""CreatedAt"" >= '2026-11-13 00:00:00' AND ""Status"" > 0));

            DELETE FROM ""TaskAssignments"" a
            WHERE a.""DueDate"" >= '2026-11-13 00:00:00'
              AND a.""DueDate"" <= '2026-11-13 23:59:59'
              AND a.""Status"" = 0
              AND EXISTS (
                  SELECT 1 FROM ""TaskAssignments"" b
                  WHERE b.""TaskId"" = a.""TaskId""
                    AND b.""AssignedToId"" = a.""AssignedToId""
                    AND b.""DueDate"" >= '2026-11-13 00:00:00'
                    AND b.""DueDate"" <= '2026-11-13 23:59:59'
                    AND b.""Status"" > 0
              );
        ");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"DB Schema migration note: {ex.Message}");
    }

    // Create worship tables if not exists
    try
    {
        db.Database.ExecuteSqlRaw(@"
            CREATE TABLE IF NOT EXISTS ""WorshipSettings"" (
                ""Id"" uuid NOT NULL PRIMARY KEY,
                ""SoloPoints"" integer NOT NULL DEFAULT 3,
                ""MosquePoints"" integer NOT NULL DEFAULT 5,
                ""QuranPoints"" integer NOT NULL DEFAULT 5,
                ""UpdatedAt"" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT INTO ""WorshipSettings"" (""Id"", ""SoloPoints"", ""MosquePoints"", ""QuranPoints"", ""UpdatedAt"")
            VALUES ('99999999-9999-9999-9999-999999999999', 3, 5, 5, CURRENT_TIMESTAMP)
            ON CONFLICT (""Id"") DO NOTHING;

            CREATE TABLE IF NOT EXISTS ""DailyWorships"" (
                ""Id"" uuid NOT NULL PRIMARY KEY,
                ""UserId"" uuid NOT NULL REFERENCES ""Users""(""Id"") ON DELETE CASCADE,
                ""Date"" timestamp without time zone NOT NULL,
                ""Subuh"" integer NOT NULL DEFAULT 0,
                ""Dzuhur"" integer NOT NULL DEFAULT 0,
                ""Ashar"" integer NOT NULL DEFAULT 0,
                ""Maghrib"" integer NOT NULL DEFAULT 0,
                ""Isya"" integer NOT NULL DEFAULT 0,
                ""QuranDone"" boolean NOT NULL DEFAULT FALSE,
                ""QuranNote"" text,
                ""TotalPointsEarned"" integer NOT NULL DEFAULT 0,
                ""CreatedAt"" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
                ""UpdatedAt"" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            ALTER TABLE ""DailyWorships"" ALTER COLUMN ""Date"" TYPE timestamp without time zone;
            ALTER TABLE ""DailyWorships"" ALTER COLUMN ""CreatedAt"" TYPE timestamp without time zone;
            ALTER TABLE ""DailyWorships"" ALTER COLUMN ""UpdatedAt"" TYPE timestamp without time zone;

            CREATE UNIQUE INDEX IF NOT EXISTS ""IX_DailyWorships_UserId_Date"" ON ""DailyWorships"" (""UserId"", ""Date"");
        ");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Worship table migration note: {ex.Message}");
    }
}

app.Run();
