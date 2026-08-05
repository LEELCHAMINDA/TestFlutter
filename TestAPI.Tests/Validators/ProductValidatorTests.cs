using FluentAssertions;
using FluentValidation.TestHelper;
using TestAPI.Models.Dtos;
using TestAPI.Validators;

namespace TestAPI.Tests.Validators;

public class ProductValidatorTests
{
    private readonly CreateProductRequestValidator _createValidator = new();
    private readonly UpdateProductRequestValidator _updateValidator = new();

    #region CreateProductRequestValidator Tests

    [Fact]
    public async Task CreateValidator_ValidRequest_ShouldNotHaveErrors()
    {
        // Arrange
        var request = new CreateProductRequest("Product", 10m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public async Task CreateValidator_EmptyName_ShouldHaveError()
    {
        // Arrange
        var request = new CreateProductRequest("", 10m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public async Task CreateValidator_NullName_ShouldHaveError()
    {
        // Arrange
        var request = new CreateProductRequest(null, 10m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public async Task CreateValidator_NameExceeds200Chars_ShouldHaveError()
    {
        // Arrange
        var longName = new string('A', 201);
        var request = new CreateProductRequest(longName, 10m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public async Task CreateValidator_NameExactly200Chars_ShouldNotHaveError()
    {
        // Arrange
        var validName = new string('A', 200);
        var request = new CreateProductRequest(validName, 10m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldNotHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public async Task CreateValidator_NegativePrice_ShouldHaveError()
    {
        // Arrange
        var request = new CreateProductRequest("Product", -1m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Price);
    }

    [Fact]
    public async Task CreateValidator_ZeroPrice_ShouldNotHaveError()
    {
        // Arrange
        var request = new CreateProductRequest("Product", 0m, "Desc", 5, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldNotHaveValidationErrorFor(x => x.Price);
    }

    [Fact]
    public async Task CreateValidator_NegativeStock_ShouldHaveError()
    {
        // Arrange
        var request = new CreateProductRequest("Product", 10m, "Desc", -1, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Stock);
    }

    [Fact]
    public async Task CreateValidator_ZeroStock_ShouldNotHaveError()
    {
        // Arrange
        var request = new CreateProductRequest("Product", 10m, "Desc", 0, true);

        // Act
        var result = await _createValidator.TestValidateAsync(request);

        // Assert
        result.ShouldNotHaveValidationErrorFor(x => x.Stock);
    }

    #endregion

    #region UpdateProductRequestValidator Tests

    [Fact]
    public async Task UpdateValidator_ValidRequest_ShouldNotHaveErrors()
    {
        // Arrange
        var request = new UpdateProductRequest("Product", 10m, "Desc", 5, true);

        // Act
        var result = await _updateValidator.TestValidateAsync(request);

        // Assert
        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public async Task UpdateValidator_EmptyName_ShouldHaveError()
    {
        // Arrange
        var request = new UpdateProductRequest("", 10m, "Desc", 5, true);

        // Act
        var result = await _updateValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public async Task UpdateValidator_NegativePrice_ShouldHaveError()
    {
        // Arrange
        var request = new UpdateProductRequest("Product", -1m, "Desc", 5, true);

        // Act
        var result = await _updateValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Price);
    }

    [Fact]
    public async Task UpdateValidator_NegativeStock_ShouldHaveError()
    {
        // Arrange
        var request = new UpdateProductRequest("Product", 10m, "Desc", -1, true);

        // Act
        var result = await _updateValidator.TestValidateAsync(request);

        // Assert
        result.ShouldHaveValidationErrorFor(x => x.Stock);
    }

    #endregion
}
