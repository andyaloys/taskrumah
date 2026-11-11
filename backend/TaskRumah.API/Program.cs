using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text.Json.Serialization;
using TaskRumah.API.Data;
using TaskRumah.API.Services;

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

    // Update existing records to align with Jakarta Time (WIB)
    try
    {
        db.Database.ExecuteSqlRaw(@"
            UPDATE ""TaskAssignments""
            SET ""DueDate"" = ""DueDate"" - INTERVAL '7 hours'
            WHERE EXTRACT(HOUR FROM ""DueDate"" AT TIME ZONE 'UTC') = 23;
        ");

        db.Database.ExecuteSqlRaw(@"
            UPDATE ""TaskAssignments""
            SET ""DueDate"" = ""DueDate"" + INTERVAL '16 hours 59 minutes 59 seconds'
            WHERE EXTRACT(HOUR FROM ""DueDate"" AT TIME ZONE 'UTC') = 0 AND EXTRACT(MINUTE FROM ""DueDate"" AT TIME ZONE 'UTC') = 0;
        ");

        db.Database.ExecuteSqlRaw(@"
            UPDATE ""Users""
            SET ""LastStreakDate"" = ""LastStreakDate"" - INTERVAL '7 hours'
            WHERE EXTRACT(HOUR FROM ""LastStreakDate"" AT TIME ZONE 'UTC') = 0;
        ");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Data migration note: {ex.Message}");
    }
}

app.Run();

