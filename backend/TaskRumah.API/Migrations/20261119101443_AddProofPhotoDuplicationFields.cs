using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TaskRumah.API.Migrations
{
    /// <inheritdoc />
    public partial class AddProofPhotoDuplicationFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DuplicateWarning",
                table: "TaskAssignments",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDuplicateProof",
                table: "TaskAssignments",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ProofPhotoHash",
                table: "TaskAssignments",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "ProofVisualHash",
                table: "TaskAssignments",
                type: "bigint",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DuplicateWarning",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "IsDuplicateProof",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ProofPhotoHash",
                table: "TaskAssignments");

            migrationBuilder.DropColumn(
                name: "ProofVisualHash",
                table: "TaskAssignments");
        }
    }
}
