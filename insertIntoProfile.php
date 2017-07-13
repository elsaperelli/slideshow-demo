<?php
$servername = "52.14.54.114";
$username = "emotiveuser";
$password = "emotive2017";
$dbname = "emotivedb";

// create connection
$connection = mysqli_connect($servername, $username, $password, $dbname);

// check connection
if (mysqli_connect_errno()) {
    echo "Failed to connect to MySQL: " . mysqli_connect_error();
}

// select all from the table 'Users'
$sql = "SELECT * FROM Users";

// check if there are results
if ($result = mysqli_query($connection, $sql)) {
    // create a results array and a temporary one to hold the data
    $resultArray = array();
    $tempArray = array();

    // loop through each row in the result set
    while($row = $result->fetch_object()) {
        // add each row to results array
        $tempArray = $row;
        array_push($resultArray, $tempArray);
    }

    // encode the array to JSON and output the results
    echo json_encode($resultArray);
}

// close connection
mysqli_close($connection);
?>