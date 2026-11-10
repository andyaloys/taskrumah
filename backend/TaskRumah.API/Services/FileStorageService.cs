namespace TaskRumah.API.Services;

public class FileStorageService
{
    private readonly IWebHostEnvironment _env;
    private readonly IConfiguration _config;

    public FileStorageService(IWebHostEnvironment env, IConfiguration config)
    {
        _env = env;
        _config = config;
    }

    public async Task<string> SaveFileAsync(IFormFile file, string subfolder = "uploads")
    {
        var uploadPath = Path.Combine(_env.WebRootPath, subfolder);
        Directory.CreateDirectory(uploadPath);

        var extension = Path.GetExtension(file.FileName);
        var fileName = $"{Guid.NewGuid()}{extension}";
        var filePath = Path.Combine(uploadPath, fileName);

        using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/{subfolder}/{fileName}";
    }

    public void DeleteFile(string? relativeUrl)
    {
        if (string.IsNullOrEmpty(relativeUrl)) return;
        var filePath = Path.Combine(_env.WebRootPath, relativeUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(filePath))
            File.Delete(filePath);
    }
}
