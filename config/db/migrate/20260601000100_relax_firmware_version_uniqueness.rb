# frozen_string_literal: true

ROM::SQL.migration do
  up do
    run "ALTER TABLE firmware DROP CONSTRAINT IF EXISTS firmwares_version_key;"
    run <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'firmwares_version_kind_key') THEN
          ALTER TABLE firmware ADD CONSTRAINT firmwares_version_kind_key UNIQUE (version, kind);
        END IF;
      END $$;
    SQL
  end

  down do
    run "ALTER TABLE firmware DROP CONSTRAINT IF EXISTS firmwares_version_kind_key;"
    run <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'firmwares_version_key') THEN
          ALTER TABLE firmware ADD CONSTRAINT firmwares_version_key UNIQUE (version);
        END IF;
      END $$;
    SQL
  end
end
