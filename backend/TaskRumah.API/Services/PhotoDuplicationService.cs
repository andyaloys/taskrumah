using System.Numerics;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using SkiaSharp;
using TaskRumah.API.Data;
using TaskRumah.API.Models;

namespace TaskRumah.API.Services;

public interface IPhotoDuplicationService
{
    string ComputeSha256(byte[] data);
    long? ComputeDHash64(byte[] data);
    int CalculateSimilarity(long hash1, long hash2);
    Task<DuplicationCheckResult> CheckDuplicationAsync(
        Guid userId, 
        byte[] photoBytes, 
        Guid? currentAssignmentId, 
        string? currentTaskTitle = null);
}

public class DuplicationCheckResult
{
    public bool IsIdentical { get; set; }
    public bool IsVisuallySimilar { get; set; }
    public int SimilarityPercentage { get; set; }
    public string? MatchedTaskTitle { get; set; }
    public DateTime? MatchedDate { get; set; }
    public string? RejectionMessage { get; set; }
    public string? WarningMessage { get; set; }
    public string PhotoHash { get; set; } = string.Empty;
    public long? VisualHash { get; set; }
}

public class PhotoDuplicationService : IPhotoDuplicationService
{
    private readonly AppDbContext _db;
    private readonly ILogger<PhotoDuplicationService> _logger;

    public PhotoDuplicationService(AppDbContext db, ILogger<PhotoDuplicationService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public string ComputeSha256(byte[] data)
    {
        var hashBytes = SHA256.HashData(data);
        return Convert.ToHexString(hashBytes).ToLowerInvariant();
    }

    public long? ComputeDHash64(byte[] data)
    {
        try
        {
            using var inputStream = new MemoryStream(data);
            using var original = SKBitmap.Decode(inputStream);
            if (original == null) return null;

            // Resize to 9 width x 8 height in grayscale
            var imageInfo = new SKImageInfo(9, 8, SKColorType.Gray8, SKAlphaType.Opaque);
            var sampling = new SKSamplingOptions(SKFilterMode.Linear);
            using var resized = original.Resize(imageInfo, sampling);
            if (resized == null) return null;

            ulong hash = 0;
            int bit = 0;

            for (int y = 0; y < 8; y++)
            {
                for (int x = 0; x < 8; x++)
                {
                    byte left = resized.GetPixel(x, y).Red;
                    byte right = resized.GetPixel(x + 1, y).Red;

                    if (left > right)
                    {
                        hash |= (1UL << bit);
                    }
                    bit++;
                }
            }

            return unchecked((long)hash);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to compute visual dHash for image");
            return null;
        }
    }

    public int CalculateSimilarity(long hash1, long hash2)
    {
        ulong u1 = unchecked((ulong)hash1);
        ulong u2 = unchecked((ulong)hash2);
        int distance = BitOperations.PopCount(u1 ^ u2);
        double similarity = (64.0 - distance) / 64.0 * 100.0;
        return (int)Math.Round(similarity);
    }

    public async Task<DuplicationCheckResult> CheckDuplicationAsync(
        Guid userId, 
        byte[] photoBytes, 
        Guid? currentAssignmentId, 
        string? currentTaskTitle = null)
    {
        var sha256 = ComputeSha256(photoBytes);
        var visualHash = ComputeDHash64(photoBytes);

        var result = new DuplicationCheckResult
        {
            PhotoHash = sha256,
            VisualHash = visualHash
        };

        // Query historical submissions of this user (submitted or approved)
        var recentAssignments = await _db.TaskAssignments
            .Include(a => a.Task)
            .Where(a => a.AssignedToId == userId 
                     && a.Id != currentAssignmentId 
                     && a.ProofPhotoUrl != null 
                     && (a.Status == AssignmentStatus.Approved || a.Status == AssignmentStatus.Submitted))
            .OrderByDescending(a => a.CompletedAt ?? a.CreatedAt)
            .Take(100)
            .ToListAsync();

        // 1. Check exact SHA-256 match (Identical file uploaded)
        var identical = recentAssignments.FirstOrDefault(a => 
            !string.IsNullOrEmpty(a.ProofPhotoHash) && 
            string.Equals(a.ProofPhotoHash, sha256, StringComparison.OrdinalIgnoreCase));

        if (identical != null)
        {
            var taskTitle = identical.Task?.Title ?? "tugas sebelumnya";
            var dateStr = (identical.CompletedAt ?? identical.DueDate).ToString("dd MMM yyyy");

            result.IsIdentical = true;
            result.SimilarityPercentage = 100;
            result.MatchedTaskTitle = taskTitle;
            result.MatchedDate = identical.CompletedAt ?? identical.DueDate;
            result.RejectionMessage = $"Foto bukti ini sama persis dengan yang pernah kamu unggah pada tugas '{taskTitle}' ({dateStr}). Silakan ambil foto bukti baru yang asli ya! 😊";
            
            _logger.LogInformation("Duplicate photo rejected (100% SHA-256 match) for user {UserId}. Matched assignment {AssignmentId}", userId, identical.Id);
            return result;
        }

        // 2. Check visual similarity (dHash) if visual hash is available
        if (visualHash.HasValue)
        {
            int highestSimilarity = 0;
            TaskAssignment? bestMatch = null;

            foreach (var item in recentAssignments)
            {
                if (item.ProofVisualHash.HasValue)
                {
                    int sim = CalculateSimilarity(visualHash.Value, item.ProofVisualHash.Value);
                    if (sim > highestSimilarity)
                    {
                        highestSimilarity = sim;
                        bestMatch = item;
                    }
                }
            }

            // If similarity is 88% or higher (Hamming distance <= 7 or 8)
            if (highestSimilarity >= 88 && bestMatch != null)
            {
                var taskTitle = bestMatch.Task?.Title ?? "tugas sebelumnya";
                var dateStr = (bestMatch.CompletedAt ?? bestMatch.DueDate).ToString("dd MMM yyyy");

                result.IsVisuallySimilar = true;
                result.SimilarityPercentage = highestSimilarity;
                result.MatchedTaskTitle = taskTitle;
                result.MatchedDate = bestMatch.CompletedAt ?? bestMatch.DueDate;
                result.WarningMessage = $"⚠️ Foto {highestSimilarity}% mirip dengan bukti tugas '{taskTitle}' pada {dateStr}";

                _logger.LogInformation("Visually similar photo detected ({Sim}%) for user {UserId}. Matched assignment {AssignmentId}", 
                    highestSimilarity, userId, bestMatch.Id);
            }
        }

        return result;
    }
}
