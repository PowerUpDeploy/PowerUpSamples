function Read-XMLValue($filename, $xpath, $element) {
	$file = get-item $filename;
	$x = [xml] (Get-Content $file)
	Select-Xml -xml $x  -XPath $xpath |
    % {
        $value = $_.Node.$element;
		return $value;
      }
}

function Write-XMLValue($filename, $xpath, $element, $filenameout, $value) {
	$file = get-item $filename;
	$x = [xml] (Get-Content $file)
	Select-Xml -xml $x  -XPath $xpath |
    % {
        $_.Node.$element = $value;
      }
	$x.Save($filenameout);
}

function Remove-XMLNode($filename, $xpath, $filenameout) {
	$file = get-item $filename;
	$x = [xml] (Get-Content $file)
	#Select-Xml -xml $x  -XPath $xpath |
    #% {
	#		$_.Node.RemoveAll();
    #  }
	Select-Xml -xml $x  -XPath $xpath |
    % {
		$_.Node.ParentNode.RemoveChild($_.Node);
      }
	$x.Save($filenameout);
}

export-modulemember -function Read-XMLValue, Write-XMLValue, Remove-XMLNode