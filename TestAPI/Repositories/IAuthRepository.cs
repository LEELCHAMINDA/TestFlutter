using TestAPI.Models;

namespace TestAPI.Repositories;

/// <summary>
/// Interface for user authentication operations.
/// </summary>
public interface IAuthRepository
{
    /// <summary>
    /// Gets a user by username or email.
    /// </summary>
    Task<User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail);

    /// <summary>
    /// Gets a user by ID.
    /// </summary>
    Task<User?> GetUserByIdAsync(int id);

    /// <summary>
    /// Creates a new user.
    /// </summary>
    Task<User> CreateUserAsync(User user);

    /// <summary>
    /// Updates the last login date for a user.
    /// </summary>
    Task UpdateLastLoginAsync(int userId);

    /// <summary>
    /// Checks if a username already exists.
    /// </summary>
    Task<bool> UsernameExistsAsync(string username);

    /// <summary>
    /// Checks if an email already exists.
    /// </summary>
    Task<bool> EmailExistsAsync(string email);
}
