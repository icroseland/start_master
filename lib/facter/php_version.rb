Facter.add(:php_version) do
  confine kernel: 'Linux'

  setcode do
    php = Facter::Core::Execution.which('php')

    if php
      output = Facter::Core::Execution.execute(
        "#{php} -r 'echo PHP_MAJOR_VERSION . \".\" . PHP_MINOR_VERSION;'",
        on_fail: nil
      )

      output.strip unless output.nil? || output.strip.empty?
    end
  end
end
